module Mcl
  Mcl.reloadable(:Gamemode)
  class Gamemode < Handler
    def setup
      setup_parsers
    end

    def setup_parsers
      register_command "c" do |handler, player, command, target, optparse|
        handler.gm(1, target)
      end
      register_command "s" do |handler, player, command, target, optparse|
        handler.gm(0, target)
      end
      register_command "spec" do |handler, player, command, target, optparse|
        handler.gm(3, target)
      end
    end

    def gm mode, target
      $mcl.server.invoke "/gamemode #{mode} #{target}"
    end
  end
end
