module Mcl
  class ConsoleServer
    attr_reader :app, :server, :socket, :sessions, :halting, :log

    def initialize app
      @app = app
      @log = Log.new(self)
      @sessions = []
      @halting = false
      @providers = (@app.config["console_socket"] || "none").split("||").map(&:strip).map do |prov|
        prov.start_with?("tcp") ? StringExpandRange.expand(prov.gsub(/(?<!:)\[/, ":[")) : prov
      end.flatten
    end

    def bind_ip
      # DO NOT CHANGE THIS HERE!
      "127.0.0.1"
    end

    def new_session *a
      Session.new(*a)
    end

    def spawn
      providers = @providers.dup

      begin
        prov = providers.shift

        if prov == "none"
          spawn_none(prov)
        elsif prov == "unix"
          spawn_unix(prov)
        elsif prov.start_with?("tcp")
          spawn_tcp(prov)
        else
          raise "Unknown socket provider `#{prov}'"
        end

        spawn_server
      rescue
        @app.log.warn "[ConsoleServer] Failed to bind via `#{prov}': (#{$!.class}) #{$!.message}"
        providers.any? ? retry : raise("Couldn't bind console server to any of the given methods!")
      end
    end

    def sock_info_path
      "#{ROOT}/tmp/#{@app.instance}.sockinfo"
    end

    def socket_path
      "#{ROOT}/tmp/#{@app.instance}-console.socket"
    end

    def save_socket_info sockinfo
      File.open(sock_info_path, "w") {|f| f.puts sockinfo }
    end

    def push_log msg
      @sessions.each{|s| s.shell.push_log msg }
    end

    def push_mlog msg
      @sessions.each{|s| s.shell.push_mlog msg }
    end

    def shutdown!
      if @server
        @halting = true
        @sessions.each{|s| Thread.new{s.terminate "server is shutting down"} }
        sleep 0.25
        max_wait = app.config["console_maxwait"].presence || 30
        begin
          Timeout::timeout(max_wait * 2) do
            until @sessions.empty?
              sleep 1
              @app.log.debug "[ConsoleServer] Waiting for #{@sessions.length} sessions to exit..."
            end
          end
        rescue
          @app.log.debug "[ConsoleServer-FAILSAFE] something went wrong in the session termination process, killed!"
        end
        @server.kill
        @socket.close if @socket rescue IOError
        File.unlink(sock_info_path) if File.exist?(sock_info_path)
        File.unlink(socket_path) if @socket.is_a?(UNIXSocket) && File.exist?(socket_path) && File.socket?(socket_path)
      end
    end

    def spawn_unix prov
      if Mcl.windows?
        @app.log.debug "[ConsoleServer] skipped unix socket (not supported on windows)"
      else
        @socket = UNIXServer.new(socket_path)
        save_socket_info("unix=#{socket_path}")
        @app.log.info "[ConsoleServer] opened socket in `#{socket_path}'"
      end
    end

    def spawn_tcp prov
      port = prov.split(":").last
      @socket = TCPServer.new(bind_ip, port)
      save_socket_info("tcp=#{bind_ip}:#{port}")
      @app.log.info "[ConsoleServer] is listening on #{bind_ip}:#{port}"
    end

    def spawn_none prov
      @app.log.info "[ConsoleServer] is deactivated"
      save_socket_info("none")
    end

    def vanish session
      @sessions.delete(session)
    end

    def spawn_server
      return unless @socket
      Thread.main[:mcl_console_server] = @server = Thread.new do
        loop do
          Thread.current.abort_on_exception = true if @app.config["dev"]

          # terminate sessions and quit loop
          Thread.current.kill if @halting || Thread.current != Thread.main[:mcl_console_server]

          loop do
            Thread.start(@socket.accept) do |sock|
              if @halting
                @socket.close
                Thread.current.kill
              else
                begin
                  begin
                    session = new_session(self, Thread.current, sock)
                    @sessions << session
                    session.helo!
                  rescue
                    client_id = session.client_id rescue nil
                    app.log.warn("[ConsoleServer] session `#{client_id || "unknown"}' prematurely terminated: #{$!.class.name}: #{$!.message}")
                    raise
                  end
                  session.loop!
                ensure
                  session.socket.close rescue nil
                  vanish(session)
                end
              end
            end
          end
        end
      end
    end
  end
end
