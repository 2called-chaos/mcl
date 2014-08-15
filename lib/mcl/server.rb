module Mcl
  class Server
    attr_reader :app, :status, :players
    attr_accessor :version, :boottime, :world
    include Getters
    include IO

    def initialize app
      @app = app
      @version = $mcl_server_version
      @boottime = $mcl_server_boottime
      @world = $mcl_server_world
      @status = :stopped # booting, running, stalled, stopping
      @players = PlayerManager.new(app, self)
      setup_local
      setup_ipc
    end

    def setup_local

    end

    def setup_ipc
      case app.config["ipc"]["adapter"]
        when "wrap"   then self.extend IPC::Wrap
        when "screen" then self.extend IPC::Screen
        when "tmux"   then self.extend IPC::Tmux
      end
      ipc_setup
    end

    def update_status status
      @status = status.to_sym
    end

    def died?
      ipc_died?
    end

    def alive?
      !died?
    end

    def msg player, msg
      ipc_invoke("/msg #{player} #{msg}")
    end

    def invoke cmd
      ipc_invoke(cmd)
    end



    def gm mode, target
      invoke %{/gamemode #{mode} #{target}}
    end

    def traw player, msg = "", opts = {}
      opts[:text] ||= msg
      invoke %{/tellraw #{player} #{opts.to_json}}
    end

    def trawm player, *msgs
      r = msgs.map do |msg|
        msg.is_a?(Hash) ? msg : {text: msg}
      end
      invoke %{/tellraw #{player} [#{r.map(&:to_json).join(",")}]}
    end
  end
end

__END__

=======
= IPC =
=======

#ipc_setup
#ipc_spawn             -- collector setup
#ipc_invoke(cmd)       -- invoke command
#ipc_read(&blk)        -- yield input to callback
#ipc_restart           -- restart server
