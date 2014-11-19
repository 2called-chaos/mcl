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
            rescue StandardError => e
              if e.is_a?(Errno::ECONNRESET) || e.message =~ /stream closed/i || e.message =~ /closed stream/i
                transport_reconnect(e)
              else
                sync do
                  _print_line "[Tfetcher] #{e.backtrace[0]}: #{e.message} (#{e.class})"
                  e.backtrace[1..-1].each{|m| _print_line "[Tfetcher]        from #{m}" }
                end
              end
            end
            sleep 1
          end
        end
      end

      def transport_reconnect ex = nil
        return if $cc_client_exiting
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
        if @socket
          @socket.close rescue IOError
          debug "Closed socket (#{@socket.class})"
        end
      # rescue
      end

      def transport_read
        @socket.gets.tap { _t_socket_stats[:mreceived].succ! }
      end

      def transport_write msg
        _t_socket_stats[:msend].succ!
        @socket << msg
        @socket.flush
      rescue Errno::EPIPE
        transport_reconnect($!)
      end

      def _t_socket_stats socket = nil
        if socket
          socket.instance_variable_set(:"@xiostats", { msend: "0", mreceived: "0", connected: Time.current })
        else
          @socket.instance_variable_get(:"@xiostats")
        end
      end

      def _t_connect_unix path
        @socket = UNIXSocket.new(path)
        _t_socket_stats(@socket)
        debug "Opened UNIX socket connection to `#{path}'"
      end

      def _t_connect_tcp hostname_with_port
        @socket = TCPSocket.open(*hostname_with_port.split(":"))
        _t_socket_stats(@socket)
        debug "Opened TCP socket connection to `#{hostname_with_port}'"
      end

      def _t_connect_none
        abort "[BoundToNoneError] ConsoleServer is deactivated (either explicitly or because other socket providers failed to initialize).", 1
      end
    end
  end
end
