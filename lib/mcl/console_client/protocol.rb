module Mcl
  class ConsoleClient
    module Protocol
      extend ActiveSupport::Concern
      PROTOCOL_VERSION = "1"

      def _protocol_message msg
        "\0@PROTOCOL@#{PROTOCOL_VERSION}##{msg}"
      end

      def _handle_protocol msg, &block
        if @opts[:snoop]
          block.try(:call, c("[SNOOP] #{msg}", :black))
        end
        zbyte, prot, payload = msg.split("@")
        raise "ProtNoZeroByte" unless zbyte == "\0"
        version, action_data = payload.split("#")
        action_data_chunks = action_data.split(":")
        action, data = action_data_chunks.shift.gsub("/", "_"), action_data_chunks.join(":")

        if respond_to?("_pt_#{action}") || respond_to?("_pt_#{action}_#{data}")
          if version == PROTOCOL_VERSION
            if respond_to?("_pt_#{action}_#{data}")
              send("_pt_#{action}_#{data}", msg, data)
            else
              send("_pt_#{action}", msg, data)
            end
          else
            print_line c("Protocol version mismatch (#{version} != #{PROTOCOL_VERSION})!", :red)
            print_line c("Try restarting the console if you just updated MCL.", :red)
          end
        else
          print_line c("Unknown protocol instruction: #{action}", :red)
        end
      rescue StandardError => e
        sync do
          _print_line c("Malformed protocol instruction: #{msg}", :red)
          _print_line "#{e.backtrace[0]}: #{e.message} (#{e.class})"
          e.backtrace[1..-1].each{|m| _print_line "        from #{m}" }
        end
      end

      def self.discard *meths
        [*meths].each do |meth|
          define_method("_pt_#{meth}"){|*a|}
        end
      end

      # ============
      # = Protocol =
      # ============
      discard :ack_input

      def _pt_session_state_ready msg, data
        protocol "session/identify:#{CLIENT_NAME}"
      end

      def _pt_ack_input_exit *a
        Thread.main.exit
      end

      def _pt_net_socket_close *a
        @socket.try(:close)
      end

      def _pt_session_env_push msg, data
        save_env @instance, data
      end

      def _pt_srv_req_env_from_client msg, data
        protocol "session/env_push:#{load_env(@instance)}"
      end
    end
  end
end
