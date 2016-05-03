module Mcl
  Mcl.reloadable(:HMclCheats)
  ## Cheats (I'm not judging your wiener)
  # !l0 [target]
  # !l30 [target]
  # !l1337 [target]
  # !give [*args]
  # !balls [target]
  # !portal [target]
  # !endportal [target]
  # !boat [target]
  # !minecart [target]
  # !pick [target]
  # !upick [target]
  # !shovel [target]
  # !ushovel [target]
  # !axe [target]
  # !uaxe [target]
  # !speedegg [boost] [target]
  # !slapbread [target]
  # !slaystick [target]
  # !lootbrick [boost] [target]
  class HMclCheats < Handler
    def setup
      register_l0(:guest, :mod)
      register_l30(:mod)
      register_l1337(:mod)
      register_give(:admin)
      register_balls(:mod)
      register_portal(:mod)
      register_endportal(:mod)
      register_boat(:mod)
      register_minecart(:mod)
      register_pick(:mod)
      register_upick(:mod)
      register_shovel(:mod)
      register_ushovel(:mod)
      register_axe(:mod)
      register_uaxe(:mod)
      register_speedegg(:mod)
      register_slapbread(:mod)
      register_slaystick(:mod)
      register_lootbrick(:mod)
      register_collect(:mod)
    end

    def register_l0 acl_level, acl_level_others
      register_command :l0, desc: "removes all levels from you or a target", acl: acl_level do |player, args|
        acl_verify(player, acl_level_others) if args.first && args.first != player
        $mcl.server.invoke "/xp -10000L #{args.first || player}"
      end
    end

    def register_l30 acl_level
      register_command :l30, desc: "adds 30 levels to you or a target", acl: acl_level do |player, args|
        $mcl.server.invoke "/xp 30L #{args.first || player}"
      end
    end

    def register_l1337 acl_level
      register_command :l1337, desc: "sets your or target's level to 1337", acl: acl_level do |player, args|
        $mcl.server.invoke "/xp -10000L #{args.first || player}"
        $mcl.server.invoke "/xp 1337L #{args.first || player}"
      end
    end

    def register_give acl_level
      register_command :give, desc: "alias for the /give command", acl: acl_level do |player, args|
        if args.count == 0
          trawt(player, "give", {text: "!give requires at least one argument!", color: "red"})
        elsif args.count == 1
          $mcl.server.invoke "/execute #{player} ~ ~ ~ /give #{player} #{args.join(" ")}"
        elsif args.count == 2 && args[1].to_i != 0
          stacks = args[1].to_i / 64
          rest = args[1].to_i % 64
          stacks.times{ $mcl.server.invoke "/execute #{player} ~ ~ ~ /give #{player} #{args[0]} 64" }
          $mcl.server.invoke "/execute #{player} ~ ~ ~ /give #{player} #{args[0]} #{rest}" if rest > 0
        else
          if args.last.to_i != 0
            stacks = args.last.to_i / 64
            rest = args.last.to_i % 64
            stacks.times{ $mcl.server.invoke "/execute #{player} ~ ~ ~ /give #{args[0]} #{args[1]} 64" }
            $mcl.server.invoke "/execute #{player} ~ ~ ~ /give #{args[0]} #{args[1]} #{rest}" if rest > 0
          else
            $mcl.server.invoke "/execute #{player} ~ ~ ~ /give #{args.join(" ")}"
          end
        end
      end
    end

    def register_balls acl_level
      register_command :balls, desc: "gives you or target 16 ender perls", acl: acl_level do |player, args|
        $mcl.server.invoke "/give #{args.first || player} ender_pearl 16"
      end
    end

    def register_portal acl_level
      register_command :portal, desc: "summons a nether portal at your/targets feet", acl: acl_level do |player, args|
        $mcl.server.invoke "/execute #{args.first || player} ~ ~ ~ setblock ~ ~ ~ portal"
      end
    end

    def register_endportal acl_level
      register_command :endportal, desc: "summons an end portal at your/targets feet", acl: acl_level do |player, args|
        $mcl.server.invoke "/execute #{args.first || player} ~ ~ ~ setblock ~ ~ ~ end_portal"
      end
    end

    def register_boat acl_level
      register_command :boat, desc: "summons a boat above your or target's head", acl: acl_level do |player, args|
        $mcl.server.invoke "/execute #{args.first || player} ~ ~ ~ summon Boat ~ ~2 ~"
      end
    end

    def register_minecart acl_level
      register_command :minecart, desc: "summons a minecart above your or target's head", acl: acl_level do |player, args|
        $mcl.server.invoke "/execute #{args.first || player} ~ ~ ~ summon MinecartRideable ~ ~2 ~"
      end
    end

    def register_pick acl_level
      register_command :pick, desc: "gives you a diamond pickaxe", acl: acl_level do |player, args|
        $mcl.server.invoke %{/give #{args.first || player} minecraft:diamond_pickaxe 1 0 {display:{Name:"Cheated Pick"}}}
      end
    end

    def register_upick acl_level
      register_command :upick, desc: "gives you a highly enchanted diamond pick", acl: acl_level do |player, args|
        $mcl.server.invoke %{
          /give @a minecraft:diamond_pickaxe 1 0 {display:{Name:"OpPick"},Unbreakable:1,ench:[
            {id:16,lvl:255},{id:20,lvl:255},{id:32,lvl:255},{id:33,lvl:255},{id:35,lvl:255}],
            HideFlags:31,CanDestroy:["minecraft:stone","minecraft:grass","minecraft:dirt","minecraft:log","minecraft:planks"],Durability:-1}
        }.gsub("\n", "").squeeze(" ")
      end
    end

    def register_shovel acl_level
      register_command :shovel, desc: "gives you a diamond shovel", acl: acl_level do |player, args|
        $mcl.server.invoke %{/give #{args.first || player} minecraft:diamond_shovel 1 0 {display:{Name:"Cheated Shovel"}}}
      end
    end

    def register_ushovel acl_level
      register_command :ushovel, desc: "gives you a highly enchanted diamond shovel", acl: acl_level do |player, args|
        $mcl.server.invoke %{
          /give @a minecraft:diamond_shovel 1 0 {display:{Name:"OpShovel"},Unbreakable:1,ench:[
            {id:16,lvl:255},{id:20,lvl:255},{id:32,lvl:255},{id:33,lvl:255},{id:35,lvl:255}],
            HideFlags:31,CanDestroy:["minecraft:stone","minecraft:grass","minecraft:dirt","minecraft:log","minecraft:planks"],Durability:-1}
        }.gsub("\n", "").squeeze(" ")
      end
    end

    def register_axe acl_level
      register_command :axe, desc: "gives you a diamond axe", acl: acl_level do |player, args|
        $mcl.server.invoke %{/give #{args.first || player} minecraft:diamond_axe 1 0 {display:{Name:"Cheated Axe"}}}
      end
    end

    def register_uaxe acl_level
      register_command :uaxe, desc: "gives you a highly enchanted diamond axe", acl: acl_level do |player, args|
        $mcl.server.invoke %{
          /give @a minecraft:diamond_axe 1 0 {display:{Name:"OpAxe"},Unbreakable:1,ench:[
            {id:16,lvl:255},{id:20,lvl:255},{id:32,lvl:255},{id:33,lvl:255},{id:35,lvl:255}],
            HideFlags:31,CanDestroy:["minecraft:stone","minecraft:grass","minecraft:dirt","minecraft:log","minecraft:planks"],Durability:-1}
        }.gsub("\n", "").squeeze(" ")
      end
    end

    def register_speedegg acl_level
      register_command :speedegg, desc: "gives you a speed egg which lets you run faster", acl: acl_level do |player, args|
        boost = (args.first || 3).to_i / 10.0
        $mcl.server.invoke %{
          /give #{args.second || player} minecraft:egg 1 0 {display:{Name:"Speedegg #{(boost * 10).to_i}"},ench:[{id:0,lvl:255}],HideFlags:31,AttributeModifiers:[
            {AttributeName:"generic.movementSpeed",Name:"generic.movementSpeed",Amount:#{boost},Operation:0,UUIDMost:98288,UUIDLeast:132143}
          ]}
        }.gsub("\n", "").squeeze(" ")
      end
    end

    def register_slapbread acl_level
      register_command :slapbread, desc: "gives you a slap bread", acl: acl_level do |player, args|
        $mcl.server.invoke %{
          /give #{args.first || player} minecraft:bread 1 0 {display:{Name:"Slapbread"},ench:[{id:19,lvl:255}],AttributeModifiers:[
            {AttributeName:"generic.maxHealth",Name:"generic.maxHealth",Amount:40,Operation:0,UUIDMost:11947,UUIDLeast:137372},
            {AttributeName:"generic.knockbackResistance",Name:"generic.knockbackResistance",Amount:1,Operation:0,UUIDMost:67558,UUIDLeast:116297},
            {AttributeName:"generic.attackDamage",Name:"generic.attackDamage",Amount:0,Operation:0,UUIDMost:23120,UUIDLeast:188440}
          ]}
        }.gsub("\n", "").squeeze(" ")
      end
    end

    def register_slaystick acl_level
      register_command :slaystick, desc: "gives you a lethal stick", acl: acl_level do |player, args|
        $mcl.server.invoke %{
          /give #{args.first || player} minecraft:stick 1 0 {display:{Name:"Slaystick"},ench:[{id:20,lvl:255}],AttributeModifiers:[
            {AttributeName:"generic.maxHealth",Name:"generic.maxHealth",Amount:40,Operation:0,UUIDMost:11947,UUIDLeast:137372},
            {AttributeName:"generic.knockbackResistance",Name:"generic.knockbackResistance",Amount:1,Operation:0,UUIDMost:67558,UUIDLeast:116297},
            {AttributeName:"generic.attackDamage",Name:"generic.attackDamage",Amount:255,Operation:0,UUIDMost:23120,UUIDLeast:188440}
          ]}
        }.gsub("\n", "").squeeze(" ")
      end
    end

    def register_lootbrick acl_level
      register_command :lootbrick, desc: "gives you a loot brick", acl: acl_level do |player, args|
        boost = args.first || 255
        $mcl.server.invoke %{/give #{args.second || player} minecraft:brick 1 0 {HideFlags:31,display:{Name:"Lootbrick"},ench:[{id:21,lvl:#{boost}}]}}
      end
    end

    def register_collect acl_level
      register_command :collect, desc: "teleport items in radius (default 10) to you", acl: acl_level do |player, args|
        radius = args.detect{|a| a.to_s =~ /\A[\-0-9]+\z/ }
        radius = nil if radius == "-"
        args.delete(radius) if radius
        radius ||= 10
        target = args.first || player

        msg, cmd = "Collected items", %{/execute #{target} ~ ~ ~ tp @e[type=Item}

        if radius
          cmd << %{,r=#{radius}}
          msg << " in a #{radius} block radius around you"
        end
        cmd << %{] #{target}}
        msg << "!"

        $mcl.server.invoke(cmd)
        trawm(target, {text: msg, color: "yellow"})
      end
    end
  end
end
