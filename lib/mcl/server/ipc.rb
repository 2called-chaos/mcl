require "open3"

module Mcl
  class Server
    module IPC
      def ipc_setup
        app.graceful do
          app.log.debug "[SHUTDOWN] Closing IPC handles..."
          @_ipc_stdin.try(:close) rescue nil
          @_ipc_stdouterr.try(:close) rescue nil
        end
      end

      def ipc_spawn
        app.graceful do
          app.ipc_early_hooks
          app.log.info "[SHUTDOWN] Stopping minecraft server..."
          if @_ipc_thread
            begin
              app.server.update_status :stopping
              if Mcl.windows?
                # KILL is mapped but no other signal...
                `taskkill /PID #{@_ipc_thread.pid} >nul 2>&1`
              else
                Process.kill("TERM", @_ipc_thread.pid)
              end

              app.log.debug "[SHUTDOWN] waiting up to 30 seconds for the minecraft server to stop..."
              c = 0
              while alive? && c < 30
                c += 1
                sleep 1
              end
            rescue Errno::ESRCH, Errno::EINVAL, Errno::EPERM
              app.log.debug "[SHUTDOWN] #{$!.class.name}: #{$!.message}"
            end

            if alive?
              app.log.debug "[SHUTDOWN] killing minecraft server..."
              begin
                Process.kill("KILL", @_ipc_thread.pid)
              rescue Errno::ESRCH, Errno::EINVAL, Errno::EPERM
                app.log.debug "[SHUTDOWN] #{$!.class.name}: #{$!.message}"
              end
            end
          end
          app.server.update_status :stopped unless alive?
        end

        # bootstrap server files/config
        ipc_bootstrap!("#{root}/bootstrap")

        if $_ipc_reattach
          app.log.info "[IPC] reattaching handle..."
          @_ipc_stdin, @_ipc_stdouterr, @_ipc_thread = $_ipc_reattach
          $_ipc_reattach = nil
          app.log.debug "[IPC] server running with pid #{@_ipc_thread.pid}"
          app.handlers.each do |handler|
            app.devlog "[SETUP] Signaling SRVRDY to handler `#{handler.class.name}'", scope: "plugin_load"
            handler.srvrdy
          end
          traw("@a", "[MCL] is back!", color: "green")
        else
          app.log.info "[IPC] starting minecraft server..."
          # @_ipc_stdin, @_ipc_stdouterr, @_ipc_thread = Open3.popen2e(%{cd "#{app.server.root}" && exec #{app.config["launch_cmd"]}})
          Dir.chdir("#{app.server.root}")
          opt = Mcl.windows? ? { new_pgroup: true } : { pgroup: true }
          @_ipc_stdin, @_ipc_stdouterr, @_ipc_thread = Open3.popen2e(%{#{app.config["launch_cmd"]}}, opt)
          app.log.debug "[IPC] server running with pid #{@_ipc_thread.pid}"
        end
      end

      def ipc_invoke command
        return unless @_ipc_stdin.respond_to?(:puts)
        app.log.debug "[IPC-invoke] #{command}"
        @_ipc_stdin.puts(command)
        @_ipc_stdin.flush
      end

      def ipc_read &block
        block.call @_ipc_stdouterr.gets
      end

      def ipc_died?
        @_ipc_thread && !@_ipc_thread.alive?
      end

      def ipc_restart

      end

      def ipc_detach
        app.log.info "[IPC] detaching handle..."
        $_ipc_reattach = [@_ipc_stdin, @_ipc_stdouterr, @_ipc_thread]
        @_ipc_stdin, @_ipc_stdouterr, @_ipc_thread = nil, nil, nil
      end

      def ipc_bootstrap! bsfile
        return unless File.exist?(bsfile)
        bscontent = File.readlines(bsfile)
        version = bscontent.shift.to_s.strip
        sprops = bscontent.map(&:strip).reject{|l| l.start_with?("#") || l == "" }

        if vdata = app.get_handlers(HMclSnap2date)[0].get_version(version)
          app.log.info "[IPC] bootstrapping Minecraft server version `#{vdata[:id]}'..."
          vpath = "#{root}/#{app.config["mcv_infix"]}#{vdata[:jar_name]}"

          # download
          unless File.exist?(vpath)
            open(vdata.dig(:downloads, :server, :url), "rb") do |page|
              File.open(vpath, "wb") do |file|
                while chunk = page.read(1024)
                  file.write(chunk)
                end
              end
            end
          end

          # writing properties
          if sprops.any?
            app.log.info "[IPC] applying server properties from bootstrap..."
            properties.update(sprops)
          end

          # link & remove bsfile
          FileUtils.rm("#{root}/minecraft_server.jar", force: true) rescue nil if Mcl.windows?
          FileUtils.ln_s "#{vpath}", "#{root}/minecraft_server.jar", force: true
          File.unlink(bsfile)
        else
          raise "The specified version `#{version}' couldn't be found (try `latest' or `snapshot' or double check your selected version)"
        end
      rescue StandardError => ex
        app.log.error "# [#{ex.class}] Failed to bootstrap server: #{ex.message}"
        FileUtils.mv(bsfile, "#{bsfile}.failed")
        File.open("#{bsfile}.failed", "a+") do |f|
          f.puts nil, "# ---------- ERROR ----------", "#{ex.class}: #{ex.message}"
          ex.backtrace.each {|l| f.puts "#   #{l}"}
        end
        raise
      end
    end
  end
end
