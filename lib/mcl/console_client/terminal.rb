require "readline"

module Mcl
  class ConsoleClient
    module Terminal
      include History
      include Environment
      include Commands

      # Prefix to use for terminal commands (will not be forwared to the remote)
      TCOM_PREF = "?"

      def terminal_init
        @prompt = ->(_){ "%{green}%{ps1}%{red}> " }
        @ps1 = ->(_){ "%{instance_nd}" }
        @spool = Queue.new
        debug "TCOM_PREF is `#{TCOM_PREF}'"
        $cc_acknowledged = _protocol_message "session/identify:#{CLIENT_NAME}"
      end

      def terminal_run
        load_history
        transport_connect
        output_proc
        loop do
          receive
          sync { spool_down }
          @cprompt = nil
          $cc_client_shutdown = false
        end
      ensure
        terminal_close
      end

      def terminal_close
        begin
          transport_disconnect
        ensure
          begin
            spool_down
          ensure
            begin
              save_history
            ensure
              clear_buffer
            end
          end
        end
      end

      def debug msg = nil
        print_line(c("[DEBUG] ", :cyan) << "#{msg}") if @opts[:debug]
      end

      def cprompt
        sync do
          @cprompt ||= begin
            ucp = instance_eval(&@prompt).dup.tap do |prompt|
              ps1 = instance_eval(&@ps1).dup
              ps1.gsub!("%{instance}", @instance)
              ps1.gsub!("%{instance_nd}", @instance) unless @instance == "default"

              prompt.gsub!("%{ps1}", ps1)
            end
            _color_cprompt("#{ucp}%{reset}")
          end
        end
      end

      def _color_cprompt str
        str.gsub("%{black}",   @colorize ? "\e[30m" : "")
           .gsub("%{red}",     @colorize ? "\e[31m" : "")
           .gsub("%{green}",   @colorize ? "\e[32m" : "")
           .gsub("%{yellow}",  @colorize ? "\e[33m" : "")
           .gsub("%{blue}",    @colorize ? "\e[34m" : "")
           .gsub("%{magenta}", @colorize ? "\e[35m" : "")
           .gsub("%{cyan}",    @colorize ? "\e[36m" : "")
           .gsub("%{white}",   @colorize ? "\e[37m" : "")
           .gsub("%{reset}",   @colorize ? "\e[0m" : "")
      end

      def output_proc
        @output_proc = Thread.new do
          loop do
            begin
              sleep 0.5 if @spool.empty?
              msg = @spool.shift
              handle_protocol(msg) {|m| print_line m if m }
            rescue Exception => e
              raise if e.is_a?(SystemExit)
              sync do
                _print_line "[oProc] #{e.backtrace[0]}: #{e.message} (#{e.class})"
                e.backtrace[1..-1].each{|m| _print_line "[oProc]        from #{m}" }
              end
            end
          end
        end
      end

      def spool_down
        clear_buffer
        while !@spool.empty?
          val = @spool.shift rescue nil
          handle_protocol(val) {|m| puts val if val }
        end
        refresh_line
      end

      def refresh_line
        Readline.refresh_line
      end

      def line_buffer
        Readline.line_buffer
      end

      def clear_buffer
        max = line_buffer.to_s.length + cprompt.length
        print "\r"
        max.times { print " " }
        print "\r"
      end

      # If you print a lot at once use clear_buffer and refresh_line (like spool_down)
      def print_line *a
        sync { _print_line(*a) }
      end

      def _print_line msg, opts = {}
        opts = opts.reverse_merge(refresh: true)
        max = line_buffer.to_s.length + cprompt.length
        print "\r#{msg}"
        (max - msg.length).times { print " " }
        print "\n"
        Readline.refresh_line if opts[:refresh] && $cc_client_receiving #&& !line_buffer.nil?
      end

      def protocol msg
        if @opts[:snoop]
          print_line c("[SNOOP] > #{msg}", :black)
        end
        transport_write _protocol_message(msg) + "\r\n"
      end

      def receive
        sync do
          $cc_client_critical = true
          clear_buffer
        end
        sleep 0.05 while $cc_acknowledged

        sync do
          $cc_client_critical = false
          $cc_client_receiving = true
          clear_buffer
        end
        buf = Readline.readline(cprompt, true)
        sync do
          history_reject(buf)
          $cc_client_receiving = false
          $cc_client_critical = true
        end
        $cc_acknowledged = "#{buf}".chomp
        handle_line(buf)
      ensure
        sync { $cc_client_critical = false }
      end

      def handle_line str
        if str.nil?
          str = "exit"
          print_line "#{cprompt}#{str}"
        end
        str = str.chomp

        if str.start_with?(TCOM_PREF)
          # terminal command
          str << "help" if str == TCOM_PREF
          fw = str[1..-1].split(" ").first
          if respond_to?("_tc_#{fw}")
            send("_tc_#{fw}", str[1..-1].split(" ")[1..-1], str)
          else
            print_line c("Unknown terminal command `#{TCOM_PREF+fw}`, try `#{TCOM_PREF}help`...", :red), refresh: false
          end
        else
          $cc_client_exiting = true if ["exit", "quit"].include?(str)
          transport_write "#{str}\r\n"
        end
      end
    end
  end
end

__END__
