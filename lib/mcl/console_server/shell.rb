module Mcl
  class ConsoleServer
    class Shell
      attr_reader :session, :server, :app
      attr_accessor :colorize, :env
      include Colorize
      include Commands
      include Protocol

      def initialize(session)
        @session = session
        @server = @session.server
        @app = @server.app
        @colorize = true
        @protocol = false
        @env = {}
      end

      def encode_env data
        JSON.generate(data)
      end

      def decode_env data
        JSON.parse(data)
      end

      def apply_env data
        @env = data
        session.nick = @env["nick"]
      end

      def push_env merge = {}
        @env = @env.merge(merge)
        protocol "session/env_push:#{encode_env(@env)}"
        apply_env(@env)
      end

      alias_method :oputs, :puts
      def puts *a
        sync { session.cputs(*a) }
      end
      alias_method :echo, :puts

      alias_method :oprint, :print
      def print *a
        sync { session.cprint(*a) }
      end

      def protocol msg, force = false
        puts _protocol_message(msg) if force || @protocol
      end

      def critical &block
        session.critical(&block)
      end

      def sync &block
        session.lock.synchronize(&block)
      end

      def commands
        methods.grep(/^_cmd/).map(&:to_s).map{|s| s.gsub(/^_cmd_/, '') }
      end

      def push_log msg
        puts "#{msg}".chomp unless @env[:livelog] == false
      end

      def push_mlog msg
        puts "#{msg}".chomp unless @env[:livemlog] == false
      end

      # handle user input message
      def input str
        str = str.chomp
        app.devlog "[ConsoleServer] #{session.client_id} invoked `#{str}'", scope: "console_server"

        if str.start_with?("\0") # Protocol
          @protocol = true
          _handle_protocol(str)
        elsif str.strip.empty?
          # no input => discard
        elsif str.start_with?("!") # MCL command
          _invoke_mcl(str)
        elsif str.start_with?("/") # MC command
          _invoke_mc(str)
        elsif str.start_with?(".") # say shortcut
          _cmd_say(str)
        else # lookup command
          chunks = str.split(" ")
          if respond_to?("_cmd_#{chunks[0]}")
            var = catch(:terminate_session) do
              critical{ send("_cmd_#{chunks[0]}", str, chunks[1..-1]) }
              nil
            end
            if var
              session.terminate(var) do
                protocol "ack/input:#{str}"
              end
            end
          else
            puts c("! Unknown command `#{chunks[0]}', type `commands' to get a list.", :red)
          end
        end
      rescue
        puts c("#{$!.class}: #{$!.message}", :red)
        puts c("#{$@.first}", :red)
        app.log.warn "[ConsoleServer] #{session.client_id} - failed to handle `#{str}' (#{$!.class}: #{$!.message})"
      ensure
        protocol "ack/input:#{str}"
      end

      def banner
        puts c("##############################################################", :cyan)
        puts c("#                                                            #", :cyan)
        puts c("#  ", :cyan) << c(%q%,--.   ,--. ,-----.,--.     %, :yellow) << c(session.client_id.rjust(28, " "), :magenta)     << c("  #", :cyan)
        puts c("#  ", :cyan) << c(%q%|   `.'   |'  .--./|  |     %, :yellow) << c(%q%                      .     %, :red) << c("  #", :cyan)
        puts c("#  ", :cyan) << c(%q%|  |'.'|  ||  |    |  |     %, :yellow) << c(%q%  ,-. ,-. ,-. ,-. ,-. |  ,-.%, :red) << c("  #", :cyan)
        puts c("#  ", :cyan) << c(%q%|  |   |  |'  '--'\|  '--.  %, :yellow) << c(%q%  |   | | | | `-. | | |  |-'%, :red) << c("  #", :cyan)
        puts c("#  ", :cyan) << c(%q%`--'   `--' `-----'`-----'  %, :yellow) << c(%q%  `-' `-' ' ' `-' `-' `' `-'%, :red) << c("  #", :cyan)
        puts c("#                                                            #", :cyan)
        puts c("#  ", :cyan) << c("type ") << c("commands", :magenta) << c(" or ") << c("help", :magenta) << c(" to get started, type ") << c("exit", :magenta) << c(" to quit.") << c("  #", :cyan)
        puts c("#                                                            #", :cyan)
        puts c("##############################################################", :cyan)
      end

      def render_table table, headers = []
        [].tap do |r|
          col_sizes = table.map{|col| col.map(&:to_s).map(&:length).max }
          headers.map(&:length).each_with_index do |length, header|
            col_sizes[header] = [col_sizes[header], length].max
          end

          # header
          if headers.any?
            r << [].tap do |line|
              col_sizes.count.times do |col|
                line << headers[col].ljust(col_sizes[col])
              end
            end.join(" | ")
            r << "".ljust(col_sizes.inject(&:+) + ((col_sizes.count - 1) * 3), "-")
          end

          # records
          table[0].count.times do |row|
            r << [].tap do |line|
              col_sizes.count.times do |col|
                line << "#{table[col][row]}".ljust(col_sizes[col])
              end
            end.join(" | ")
          end
        end
      end

      # =======
      # = API =
      # =======
      def hello
        banner
        protocol "session/state:ready", true
      end

      def goodbye reason = "no apparent reason"
        puts c("!!!!!!!!!!!!!!....", :red)
        puts c("!!! ConsoleServer says bye, bye...", :red)
        puts c("!!! Reason: #{reason}", :red)
        puts c("!!!!!!!!!!!!!!....", :red)
        protocol "net/socket:close"
      end
    end
  end
end
