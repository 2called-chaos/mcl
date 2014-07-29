module Mcl
  class Server
    module IPC
      module Logfile
        def ipc_spawn
          app.graceful do
            app.log.debug "[SHUTDOWN] Closing IPC handles..."
            @_ipc_file.try(:close) rescue nil
          end
          @_ipc_file = File.open(app.server.logfile_path, "r")
          @_ipc_file.extend(File::Tail)
          @_ipc_file.interval = app.config["tick_rate"]
          @_ipc_file.return_if_eof = false
          @_ipc_file.break_if_eof = false
          @_ipc_file.backward(0)
        end

        def ipc_read &block
          @_ipc_file.tail(&block)
        end
      end
    end
  end
end

