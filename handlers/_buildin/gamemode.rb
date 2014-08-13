module Mcl
  Mcl.reloadable(:HGamemode)
  class HGamemode < Handler
    def setup
      setup_parsers
    end

    def setup_parsers
      register_command :c, :creative do |handler, player, command, target, optparse|
        handler.gm(1, target)
      end
      register_command :s, :survival do |handler, player, command, target, optparse|
        handler.gm(0, target)
      end
      register_command :spec, :spectator do |handler, player, command, target, optparse|
        handler.gm(3, target)
      end
    end

    def gm mode, target
      $mcl.server.invoke "/gamemode #{mode} #{target}"
    end
  end
end
