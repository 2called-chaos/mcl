module Mcl
  Mcl.reloadable(:HGamemode)
  class HGamemode < Handler
    def setup
      setup_parsers
    end

    def setup_parsers
      register_command :c, :creative, desc: "be creative" do |handler, player, command, target, optparse|
        handler.acl_verify(player)
        handler.gm(1, target)
      end
      register_command :s, :survival, desc: "be mortal and die!" do |handler, player, command, target, optparse|
        handler.gm(0, target)
      end
      register_command :spec, :spectator, desc: "become spectator" do |handler, player, command, target, optparse|
        handler.gm(3, target)
      end
    end

    def gm mode, target
      $mcl.server.invoke "/gamemode #{mode} #{target}"
    end
  end
end
