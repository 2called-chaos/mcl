module Mcl
  class ConsoleServer
    class Session
      attr_reader :server, :thread, :socket, :shell, :critical, :lock, :halting, :connected
      attr_accessor :client_app, :nick

      def initialize(server, thread, socket)
        @server = server
        @thread = thread
        @socket = socket
        @shell = Shell.new(self)
        @critial = false
        @lock = Monitor.new
        @connected = Time.current
        @halting = false
        @nick = nil
        @client_app = "raw_client"
      end

      def cputs *msg
        msg.each {|m| @socket << "#{m}\r\n" }
        @socket.flush rescue IOError
      end

      def cprint *msg
        msg.each {|m| @socket << "#{m}" }
        @socket.flush rescue IOError
      end

      def helo!
        @server.app.log.info "[ConsoleServer] Client #{client_id} connected"
        @shell.hello
      end

      def peer
        @peer ||= Socket.unpack_sockaddr_in(@socket.getpeername).reverse
      end

      def client_id
        "#{peer.join(":")}#{"[#{nick}]" if nick.present?}"
      end

      def max_wait
        @server.app.config["console_maxwait"].presence || 30
      end

      def critical &block
        sync { @critical = true }
        block.call
      ensure
        sync { @critical = false }
      end

      def sync &block
        @lock.synchronize(&block)
      end

      def terminate ex = nil, silent = false, &block
        @halting = true
        Timeout::timeout(max_wait) { sleep 0.25 while sync{@critical} } rescue nil
        unless silent
          reason = ""
          reason << ex if ex.is_a?(String)
          reason << "#{ex.class}: #{ex.message}" if ex.is_a?(Exception)
          reason = reason.presence || "generic"
          @shell.goodbye(reason)
          @server.app.log.info "[ConsoleServer] Client #{client_id} disconnected (#{reason})"
        end
        block.try(:call, self)
        @thread.try(:kill)
      end

      def loop!
        loop do
          begin
            # Returns nil on EOF
            while line = @socket.gets
              @shell.input(line.chomp!)
            end
          rescue
            msg = "[ConsoleServer] #{client_id} terminated: #{$!.class.name}: #{$!.message}"
            if $!.message =~ /closed stream/i
              @server.app.devlog(msg)
            else
              @server.app.handle_exception($!) {|ex| @server.app.log.error(msg) }
            end
            terminate($!, true)
          ensure
            @socket.close rescue false
            @server.vanish(self)
          end
        end
      end
    end
  end
end
