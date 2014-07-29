module Mcl
  class PlayerManager
    attr_reader :app, :server

    def initialize app, server
      @app, @server = app, server
      @app.ram[:players] ||= {}
      @uuids = {}
    end

    def _ram player = nil
      player ? @app.ram[:players][player] : @app.ram[:players]
    end

    def all
      @players
    end

    def get player
      @app.ram[:players][player]
    end

    def get_uuid uuid
      get @uuids[uuid]
    end
  end
end
