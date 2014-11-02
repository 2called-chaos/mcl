require "readline"

module Mcl
  class ConsoleClient
    module Terminal
      def terminal_init
        @prompt = "> "
        @spool = Queue.new
      end

      def terminal_run
        transport_connect
        loop do
          receive
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
            clear_buffer
          end
        end
      end

      def spool_down
        clear_buffer
        while !@spool.empty?
          val = @spool.shift rescue nil
          puts val if val
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
        max = line_buffer.to_s.length + @prompt.length
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
        max = line_buffer.to_s.length + @prompt.length
        print "\r#{msg}"
        (max - msg.length).times { print " " }
        print "\n"
        Readline.refresh_line if opts[:refresh] && $cc_client_receiving #&& !line_buffer.nil?
      end

      def receive
        $cc_client_receiving = true
        buf = Readline.readline(@prompt, true)
        $cc_client_receiving = false
        $cc_client_critical = true
        handle_line(buf)
      ensure
        $cc_client_critical = false
      end

      def handle_line str
        if str.nil?
          str = "exit"
          print_line "#{@prompt}#{str}"
        end
        str = str.chomp

        case str
        when "pry" then binding.pry
        when "moep"
          puts "local here"
          sleep 3
          puts "local here"
        else
          transport_write "#{str}\r\n"
        end
      end
    end
  end
end

__END__
