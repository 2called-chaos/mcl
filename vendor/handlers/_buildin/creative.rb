module Mcl
  Mcl.reloadable(:HMclCreative)
  ## Creative stuff
  # !skull [skull owner]
  # !head [skull owner]
  # !airblock [target]
  # !command_block [target] / !cb [target]
  # !barrier [target]
  # !cbt [target]
  class HMclCreative < Handler
    def setup
      register_skull(:member)
      register_head(:member)
      register_airblock(:builder)
      register_barrier(:builder)
      register_villager_inventory(:builder)
      register_cb(:admin)
      register_cbt(:admin)
    end

    def register_skull acl_level
      register_command :skull, desc: "gives you a player's head", acl: acl_level do |player, args|
        $mcl.server.invoke do |cmd|
          cmd.default "/give #{player} skull 1 3 {SkullOwner:#{args.first || player}}"
          cmd.since "1.13", "17w45a", "/give #{player} player_head{SkullOwner:#{args.first || player}}"
        end
      end
    end

    def register_head acl_level
      register_command :head, desc: "replaces your helm with a player's head", acl: acl_level do |player, args|
        $mcl.server.invoke do |cmd|
          cmd.default "/replaceitem entity #{player} slot.armor.head skull 1 3 {SkullOwner:#{args.first || player}}"
          cmd.since "1.13", "17w45a", "/replaceitem entity #{player} armor.head player_head{SkullOwner:#{args.first || player}}"
        end
      end
    end

    def register_airblock acl_level
      register_command :airblock, desc: "setblocks the block below you or target to dirt", acl: acl_level do |player, args|
        $mcl.server.invoke do |cmd|
          cmd.default "/execute #{args.first || player} ~ ~ ~ setblock ~ ~-1 ~ dirt"
          cmd.since "1.13", "17w45a", "/execute as #{args.first || player} at #{args.first || player} run setblock ~ ~-1 ~ dirt"
        end
      end
    end

    def register_cb acl_level
      register_command :cb, :command_block, :commandblock, desc: "gives you or target a command block", acl: acl_level do |player, args|
        $mcl.server.invoke "/give #{args.first || player} command_block"
      end
    end

    def register_barrier acl_level
      register_command :barrier, desc: "gives you or target a barrier block", acl: acl_level do |player, args|
        $mcl.server.invoke "/give #{args.first || player} barrier"
      end
    end

    def register_villager_inventory acl_level
      register_command :villagerinv, desc: "clears or sets all slots of entities to given item", acl: acl_level do |player, args|
        if args.empty?
          trawt(player, "VillagerInv", {text: "Usage: !villagerinv <selector> [<item[:amount]> [slots]]", color: "aqua"})
          trawt(player, "VillagerInv", {text: "Slot may be a range from 0-7, default: all 8 slots", color: "aqua"})
          trawt(player, "VillagerInv", {text: "e.g. !villagerinv @e[type=Villager,r=10] wheat_seeds 0-6 7", color: "aqua"})
        else
          selector = args.shift
          item = args.shift || "air"
          item << "/64" unless item["/"]
          item, amount = item.split("/")
          slots = args.join(",").sub(",,", ",") if item
          all_slots = StringExpandRange.expand("[#{slots}]")

          all_slots.each do |slot|
            $mcl.server.invoke do |cmd|
              cmd.default "/execute #{player} ~ ~ ~ /replaceitem entity #{selector} slot.villager.#{slot} #{item || "air"} #{amount}"
              cmd.since "1.13", "17w45a", "/execute as #{player} at #{player} run replaceitem entity #{selector} slot.villager.#{slot} #{item || "air"} #{amount}"
            end
          end
          trawt(player, "VillagerInv", {text: "executed #{all_slots.length} commands", color: "green"})
        end
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
  end
end
