module Mcl
  class ConsoleClient
    module Transport
      def transport_connect
        send *discover_transport

        @fetcher = Thread.new do
          loop do
            begin
              while msg = transport_read
                @spool << msg.chomp if msg.present?
              end
            rescue Errno::ECONNRESET => e
              transport_reconnect(e)
            rescue IOError => e
              unless e.message =~ /stream closed/i
                puts "[Tfetcher] #{e.backtrace[0]}: #{e.message} (#{e.class})"
                e.backtrace[1..-1].each{|m| puts "[Tfetcher]\tfrom #{m}" }
                Thread.current.kill
              end
            rescue
              puts "[Tfetcher] #{e.backtrace[0]}: #{e.message} (#{e.class})"
              e.backtrace[1..-1].each{|m| puts "[Tfetcher]\tfrom #{m}" }
            end
            sleep 1
          end
        end
      end

      def transport_reconnect ex = nil
        return if $cc_client_reconnecting
        $cc_client_reconnecting = true
        $cc_client_critical = true
        begin
          if @opts[:reconnect]
            print_line "Connection to socket lost (#{ex.try(:message) || "generic"})! Reconnecting...", refresh: false
            sleep 3
            begin
              send *discover_transport(true)
              print_line "Connected!", refresh: false
              $cc_client_critical = false
            rescue
              $cc_client_critical = false
              print_line "Connection failed! Retrying in 3 seconds...", refresh: false
              sleep 3
              retry
            end
          else
            print_line "Connection to socket lost (#{ex.try(:message) || "generic"})! Exiting...", refresh: false
            exit
          end
        ensure
          $cc_client_reconnecting = false
        end
      end

      def transport_disconnect
        @socket.close if @socket
        debug "Closed socket (#{@socket.class})"
      # rescue
      end

      def transport_read
        @socket.gets
      end

      def transport_write msg
        @socket << msg
        @socket.flush
      rescue Errno::EPIPE
        transport_reconnect($!)
      end

      def _t_connect_unix path
        @socket = UNIXSocket.new(path)
        debug "Opened UNIX socket connection to `#{path}'"
      end

      def _t_connect_tcp hostname_with_port
        @socket = TCPSocket.open(*hostname_with_port.split(":"))
        debug "Opened TCP socket connection to `#{hostname_with_port}'"
      end

      def _t_connect_none
        abort "[BoundToNoneError] ConsoleServer is deactivated (either explicitly or because other socket providers failed to initialize).", 1
      end
    end
  end
end

# hostname = 'localhost'
# port = 2000

# s =

# while line = s.gets   # Read lines from the socket
#   puts line.chop      # And print with platform line terminator
# end
# s.close               # Close the socket when done
