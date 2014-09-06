module Mcl
  class Server
    attr_reader :app, :status, :players
    attr_accessor :version, :boottime, :world
    include Helper
    include Getters
    include IPC
    include IO

    def initialize app
      @app = app
      @version = $mcl_server_version
      @boottime = $mcl_server_boottime
      @world = $mcl_server_world
      @status = $mcl_server_status || :stopped # booting, running, stalled, stopping
      ipc_setup
    end

    def update_status status
      $mcl_server_status = @status = status.to_sym
    end

    def died?
      ipc_died?
    end

    def alive?
      !died?
    end

    def invoke cmd
      ipc_invoke(cmd)
    end
  end
end
