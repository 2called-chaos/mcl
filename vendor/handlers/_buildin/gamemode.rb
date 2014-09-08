module Mcl
  Mcl.reloadable(:HMclGamemode)
  ## Gamemode (just shortcuts)
  # !s !survival
  # !c !creative
  # !adventure
  # !spec !spectator
  class HMclGamemode < Handler
    module Helper
      def gm mode, target
        $mcl.server.invoke "/gamemode #{mode} #{target}"
      end
    end
    include Helper

    def setup
      setup_parsers
    end

    def setup_parsers
      register_command(:s, :survival,     desc: "be mortal and die!", acl: :guest)   {|player, args| gm(0, args.first || player) }
      register_command(:c, :creative,     desc: "be creative"       , acl: :builder) {|player, args| gm(1, args.first || player) }
      register_command(:adventure,        desc: "be creative"       , acl: :builder) {|player, args| gm(2, args.first || player) }
      register_command(:spec, :spectator, desc: "become spectator"  , acl: :builder) {|player, args| gm(3, args.first || player) }
    end
  end
end
