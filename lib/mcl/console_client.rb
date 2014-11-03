module Mcl
  class ConsoleClient
    def self.dispatch *a, &block
      new(*a, &block).dispatch
    end

    attr_reader :opts, :opt, :argv

    # placed at the end to allow the block to override methods
    def initialize instance, argv, &block
      @instance = instance
      @colorize = true
      @argv = argv
      @opts = { debug: false, dispatch: :terminal, reconnect: true, snoop: false, colorize: true }
      @opt = OptionParser.new
      @lock = Monitor.new
      block.call(self)
      init_params
      begin
        @opt.parse!(argv)

        # patch colorize
        unless @opts[:colorize]
          def self.c *args
            args.first
          end
        end
      rescue
        puts "#{$@[0]}: #{$!.message} (#{$!.class})"
        $@[1..-1].each{|m| puts "\tfrom #{m}" }
        puts nil, "  -------------", nil, "  !> #{$!.message} (#{$!.class})", nil
        exit
      end
    end

    def init_params
      opt.banner = "Usage: mcld console [options]"
      opt.on("-o", "--connect-once", "Don't try to reconnect if connection broke") { @opts[:reconnect] = false }
      opt.on("-m", "--monochrome", "Don't colorize shell (remote may still send colored output)") { @opts[:colorize] = false }
      # opt.separator("")
      opt.on("-s", "--snoop", "Show protocol messages (in and out)") { @opts[:snoop] = true }
      opt.on("-d", "--debug", "Enable debug output") { @opts[:debug] = true }
      opt.on("-h", "--help", "Shows this help") { @opts[:dispatch] = :help }
    end

    def sync &block
      @lock.synchronize(&block)
    end

    def dispatch
      if @opts[:dispatch] == :help
        puts @opt.to_s
      else
        begin
          trap_signals
          terminal_init
          terminal_run
        rescue
          puts "#{$@[0]}: #{$!.message} (#{$!.class})"
          $@[1..-1].each{|m| puts "\tfrom #{m}" }
          puts nil, "  -------------", nil, "  !> #{$!.message} (#{$!.class})", nil
        ensure
          release_signals
        end
      end
    end

    def debug msg = nil
      puts "[DEBUG] #{msg}" if @opts[:debug]
    end

    def abort msg, exit_code = 1
      warn c(msg, :red)
      exit(exit_code) if exit_code
    end

    def use comp
      raise "Invalid class name `#{comp}'" unless comp =~ /\A[a-z0-9:]+\z/i
      extend eval(comp)
    end

    def handle_protocol msg, &block
      return nil if msg.nil?
      return false unless msg.is_a?(String)
      unless msg.start_with?("\0")
        block.try(:call, msg)
        return msg
      end
      _protocol_handle(msg, &block)
    end

    def _protocol_handle msg, &block
      if @opts[:snoop]
        block.try(:call, c("[SNOOP] #{msg}", :black))
      end
      Thread.main.exit if msg == "\0@PROTOCOL@1#ack/input:exit"
    end

    def trap_signals
      Signal.trap("INT") do
        if $cc_client_critical
          if $cc_client_shutdown
            warn "\n!> Prematurely exiting!"
            exit
          end

          puts "\ni> Shell is working, press Ctrl-C again to kill it."
          $cc_client_shutdown = true
        else
          puts "Interrupted..."
          exit
        end
      end
    end

    def release_signals
      Signal.trap("INT", "DEFAULT")
    end

    def c *args
      args.first
    end
  end
end
