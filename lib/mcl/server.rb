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

    def invoke command = nil, &block
      raise ArgumentError, "command or block must be given" if !command && !block
      cmd = block ? VersionedCommand.new(app, &block).compile(@version) : command
      cmd = cmd.call(app) if cmd.respond_to?(:call)
      ipc_invoke(cmd[0] == "/" ? cmd[1..-1] : cmd)
    end
  end
end
