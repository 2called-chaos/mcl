module Mcl
  class ConsoleServer
    module Protocol
      PROTOCOL_VERSION = "1"

      def _protocol_message msg
        "\0@PROTOCOL@#{PROTOCOL_VERSION}##{msg}"
      end

      def _handle_protocol msg
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
            app.devlog "[ConsoleServer] #{session.client_id} FAILED to handle protocol message `#{msg}' (protocol version mismatch (#{version} != #{PROTOCOL_VERSION}))!", scope: "console_server"
          end
        else
          app.devlog "[ConsoleServer] #{session.client_id} FAILED to handle protocol message `#{msg}' (unknown protocol instruction: #{action})!", scope: "console_server"
        end
      rescue StandardError => e
        app.devlog "[ConsoleServer] #{session.client_id} FAILED to handle protocol message `#{msg}' (malformed protocol instruction: #{msg})!", scope: "console_server"
        app.devlog "                #{e.message}", scope: "console_server"
      end

      def _pt_session_identify msg, data
        session.client_app = data
        protocol "srv_req_env_from_client:#{@app.instance}", true
      end

      def _pt_session_env_push msg, data
        apply_env(decode_env(data))
      end

      def _pt_session_colorize_disable msg, data
        @colorize = false
      end

      def _pt_session_colorize_enable msg, data
        @colorize = true
      end
    end
  end
end
