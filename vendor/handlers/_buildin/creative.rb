module Mcl
  Mcl.reloadable(:HMclCreative)
  ## Creative stuff
  # !skull [skull owner]
  # !head [skull owner]
  # !airblock [target]
  # !cb [target]
  # !cbt [target]
  class HMclCreative < Handler
    def setup
      register_skull(:member)
      register_head(:member)
      register_airblock(:builder)
      register_cb(:admin)
      register_cbt(:admin)
    end

    def register_skull acl_level
      register_command :skull, desc: "gives you a player's head", acl: acl_level do |player, args|
        $mcl.server.invoke "/give #{player} skull 1 3 {SkullOwner:#{args.first || player}}"
      end
    end

    def register_head acl_level
      register_command :head, desc: "replaces your helm with a player's head", acl: acl_level do |player, args|
        $mcl.server.invoke "/replaceitem entity #{player} slot.armor.head skull 1 3 {SkullOwner:#{args.first || player}}"
      end
    end

    def register_airblock acl_level
      register_command :airblock, desc: "setblocks the block below you or target to dirt", acl: acl_level do |player, args|
        $mcl.server.invoke "/execute #{args.first || player} ~ ~ ~ setblock ~ ~-1 ~ dirt"
      end
    end

    def register_cb acl_level
      register_command :cb, desc: "gives you or target a command block", acl: acl_level do |player, args|
        $mcl.server.invoke "/give #{args.first || player} command_block"
      end
    end

    def register_cbt acl_level
      register_command :cbt, desc: "inventory for command block trickery", acl: acl_level do |player, args|
        target = args.first || player
        $mcl.server.invoke "/clear #{target}"
        $mcl.server.invoke "/give #{target} command_block"
        $mcl.server.invoke "/give #{target} redstone_block"
        $mcl.server.invoke "/give #{target} stone_button"
        $mcl.server.invoke "/give #{target} repeater"
        $mcl.server.invoke "/give #{target} comparator"
        $mcl.server.invoke "/give #{target} sign"
        $mcl.server.invoke "/give #{target} diamond_sword"
      end
    end

    module Helper
      def gm mode, target
        $mcl.server.invoke "/gamemode #{mode} #{target}"
      end
    end
    include Helper
  end
end
