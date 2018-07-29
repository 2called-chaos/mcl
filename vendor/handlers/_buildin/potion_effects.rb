module Mcl
  Mcl.reloadable(:HMclPotionEffects)
  ## Potion Effects (shortcuts for overpowered effects)
  # !2damoon
  # !<3
  # !breath
  # !bunny
  # !ce !milk
  # !drugs
  # !fast
  # !faster
  # !feed
  # !gonzales
  # !haste
  # !haste2
  # !heal
  # !hearts
  # !higher
  # !hungry
  # !idontwannadie
  # !immortal
  # !jump
  # !junkie
  # !miningf
  # !nvision !nightvision !night_vision !letitbelight
  # !onehit
  # !qh
  # !qj
  # !quick !speed
  # !resist
  # !rocket
  # !slowmo !matrix
  # !starve
  # !strength
  # !uwater
  # !gimme
  class HMclPotionEffects < Handler
    def setup
      register_commands
    end

    def register_commands
      ph [:ce, :milk], :clear, "clears all your or target's effects"

      # speed
      ph [:quick, :speed], [:speed, 6000, 5],  "gives you or target 5x speed"
      ph :fast,            [:speed, 6000, 10], "gives you or target 10x speed"
      ph :faster,          [:speed, 6000, 20], "gives you or target 20x speed"
      ph :gonzales,        [:speed, 6000, 50], "gives you or target 50x speed"

      # jump
      ph :qj,        [:jump_boost, 3, 5, true], "gives you or target 5x jump boost for 3 seconds"
      ph :jump,      [:jump_boost, 6000, 5],    "gives you or target 5x jump boost"
      ph :bunny,     [:jump_boost, 6000, 10],   "gives you or target 10x jump boost"
      ph :higher,    [:jump_boost, 6000, 20],   "gives you or target 20x jump boost"
      ph :rocket,    [:jump_boost, 6000, 50],   "gives you or target 50x jump boost"
      ph :"2damoon", [:jump_boost, 6000, 125],  "gives you or target 125x jump boost"

      # haste
      ph :haste,  [:haste, 6000, 10],  "gives you or target 10x haste"
      ph :haste2, [:haste, 6000, 255], "gives you or target 255x haste"

      # minin fatuege
      ph :miningf, [:mining_fatigue, 6000, 10], "gives you or target 10x mining fatigue"

      # night vision
      ph [:nvision, :nightvision, :night_vision, :letitbelight, :cantseeshit], [:night_vision, 6000, 255], "gives you or target 255x nightvision"

      # strength
      ph :strength, [:strength, 6000, 5],   "gives you or target 5x strength"
      ph :onehit,   [:strength, 6000, 255], "gives you or target 255x strength"

      # regeneration
      ph :heal, [:regeneration, 60, 255], "gives you or target 255x regen for 60s"
      register_command(:qh, desc: "gives you or target 255x regen and saturation for 3 seconds", acl: ph_acl) do |player, args|
        player_effect(player, args.first || player, :regeneration, 3, 255, true)
        player_effect(player, args.first || player, :saturation, 3, 255, true)
      end

      # resistance
      ph :resist, [:resistance, 6000, 255], "gives you or target 255x resistance"

      # water breathing
      ph :breath, [:water_breathing, 6000, 255], "gives you or target 255x water breathing"

      # nausea
      ph :drugs,  [:nausea, 30, 255], "gives you or target 255x neusea for 30s"
      ph :junkie, [:nausea, 6000, 255], "gives you or target 255x nausea"

      # feed
      ph :hungry, [:saturation, 60, 255], "gives you or target 255x saturation for 60s"
      ph :feed,   [:saturation, 6000, 255], "gives you or target 255x saturation"

      # starve
      ph :starve, [:hunger, 120, 30], "gives you or target 120x hunger for 30s"

      # glow
      ph :glow, [:glowing, 120, 1], "gives you or target glow effect for 120s"
      ph :nuclear, [:glowing, 6000, 1], "gives you or target glow effect"

      # misc
      ph :hearts, [:absorption, 6000, 255], "gives you or target 255x absorption"
      ph :"<3",   [:absorption, 60, 255],   "gives you or target 255x absorption for 60s"
      register_command(:idontwannadie, desc: "gives you or target several OP buffs", acl: ph_acl) do |player, args|
        target = args.first || player
        player_effect player, target, :regeneration, 6000, 255
        player_effect player, target, :resistance, 6000, 255
        player_effect player, target, :strength, 6000, 255
        player_effect player, target, :absorption, 6000, 4
      end
      register_command(:slowmo, :matrix, desc: "gives you or target slowmotion for 60s", acl: ph_acl) do |player, args|
        player_effect player, args.first || player, :slowness, 60, 4
        player_effect player, args.first || player, :mining_fatigue, 60, 60
      end
      register_command(:immortal, desc: "gives you or target total OP buffs", acl: ph_acl) do |player, args|
        target = args.first || player
        player_effect player, target, :speed, 6000, 5
        player_effect player, target, :jump_boost, 6000, 3
        player_effect player, target, :regeneration, 6000, 255
        player_effect player, target, :resistance, 6000, 255
        player_effect player, target, :strength, 6000, 255
        player_effect player, target, :absorption, 6000, 4
        player_effect player, target, :saturation, 6000, 4
        player_effect player, target, :haste, 6000, 5
        player_effect player, target, :night_vision, 6000, 255
      end
      register_command(:uwater, desc: "gives you or target OP underwater buffs", acl: ph_acl) do |player, args|
        target = args.first || player
        player_effect player, target, :water_breathing, 6000, 255
        player_effect player, target, :night_vision, 6000, 255
        player_effect player, target, :speed, 6000, 10
        replace_item  target, "armor.head",  "diamond_helmet", "{ench:[{id:0,lvl:1337},{id:6,lvl:1337}],Unbreakable:1}"
        replace_item  target, "armor.chest", "diamond_chestplate", "{ench:[{id:0,lvl:1337},{id:7,lvl:1337}],Unbreakable:1}"
        replace_item  target, "armor.legs",  "diamond_leggings", "{ench:[{id:0,lvl:1337},{id:7,lvl:1337}],Unbreakable:1}"
        replace_item  target, "armor.feet",  "diamond_boots", "{ench:[{id:0,lvl:1337},{id:7,lvl:1337},{id:8,lvl:3}],Unbreakable:1}"
      end
      register_command(:gimme, desc: "gives you or target a perfect outfit", acl: ph_acl) do |player, args|
        target = args.first || player
        # weapons / tools
        give_item target, "diamond_sword", 1, %{{display:{Name:"The Butcher",Lore:["Kills everything"]},ench:[{id:16,lvl:5},{id:21,lvl:3},{id:22,lvl:3},{id:22,lvl:3},{id:70,lvl:1}]}}
        give_item target, "bow", 1, %{{display:{Name:"AK47",Lore:["Not really as good"]},ench:[{id:48,lvl:5},{id:49,lvl:2},{id:50,lvl:1},{id:51,lvl:1}]}}
        give_item target, "diamond_pickaxe", 1, %{{display:{Name:"PickMuch",Lore:["with luck!"]},ench:[{id:32,lvl:5},{id:35,lvl:3},{id:70,lvl:1}]}}
        give_item target, "diamond_pickaxe", 1, %{{display:{Name:"PickGood",Lore:["with silk!"]},ench:[{id:32,lvl:5},{id:33,lvl:1},{id:70,lvl:1}]}}
        give_item target, "diamond_shovel", 1, %{{display:{Name:"DigIt",Lore:["dig it?"]},ench:[{id:32,lvl:5},{id:33,lvl:1},{id:70,lvl:1}]}}
        give_item target, "diamond_axe", 1, %{{display:{Name:"ChopChop",Lore:["Suey!"]},ench:[{id:16,lvl:5},{id:32,lvl:5},{id:35,lvl:3},{id:70,lvl:1}]}}

        # items
        2.times {
          give_item target, "ender_pearl", 16
          version_switch do |v|
            v.default { give_item target, "fireworks", 64, %{{Fireworks:{Flight:15}}} }
            v.since("1.13", "17w45a") { give_item target, "firework_rocket", 64, %{{Fireworks:{Flight:15}}} }
          end
          give_item target, "cooked_beef", 64
        }
        give_item target, "arrow", 1
        give_item target, "flint_and_steel", 1
        give_item target, "torch", 64

        # armor
        give_item target, "diamond_helmet", 1, %{{display:{Name:"AntiBrainZ",Lore:["Don't let the zombies get your brain","Also works underwater"]},ench:[{id:4,lvl:4},{id:5,lvl:3},{id:6,lvl:1},{id:7,lvl:2},{id:70,lvl:3}]}}
        give_item target, "diamond_chestplate", 1, %{{display:{Name:"AntiPainZ",Lore:["Don't let them rip your heart!","No refund!"]},ench:[{id:0,lvl:4},{id:7,lvl:2},{id:70,lvl:3}]}}
        give_item target, "diamond_leggings", 1, %{{display:{Name:"AntiHotZ",Lore:["Protects you from hot incidents.","Doesn't work for chilli!"]},ench:[{id:1,lvl:4},{id:7,lvl:2},{id:70,lvl:3}]}}
        give_item target, "diamond_boots", 1, %{{display:{Name:"AntiSlowZ",Lore:["Run like you never did before!","With new slime technology!"]},ench:[{id:2,lvl:4},{id:3,lvl:4},{id:7,lvl:2},{id:8,lvl:3},{id:70,lvl:3}]}}
        give_item target, "elytra", 1, %{{display:{Name:"Jetpack",Lore:["Not really a jetpack!"]},ench:[{id:0,lvl:4},{id:7,lvl:2},{id:70,lvl:3}]}}
      end
    end

    module Helper
      def ph_acl
        :mod
      end

      def ph names, effect, desc
        register_command(*[*names], desc: desc, acl: ph_acl) {|player, args| player_effect(player, args.first || player, *[*effect]) }
      end

      # >1.13 dirty fix :D
      def fix_nbt nbt
        return unless nbt
        nbt = nbt.gsub("ench:[{", "Enchantments:[{")
        nbt = nbt.gsub(/display:{Name:"([^"]+)",/, 'display:{Name:"\"\1\"",')
        nbt = nbt.gsub("id:33", "id:silk_touch")
        nbt = nbt.gsub("id:35", "id:fortune")
        nbt = nbt.gsub("id:32", "id:efficiency")
        nbt = nbt.gsub("id:51", "id:infinity")
        nbt = nbt.gsub("id:50", "id:flame")
        nbt = nbt.gsub("id:49", "id:punch")
        nbt = nbt.gsub("id:48", "id:power")
        nbt = nbt.gsub("id:70", "id:mending")
        nbt = nbt.gsub("id:22", "id:sweeping_edge")
        nbt = nbt.gsub("id:21", "id:looting")
        nbt = nbt.gsub("id:22", "id:sweeping_edge")
        nbt = nbt.gsub("id:16", "id:sharpness")
        nbt = nbt.gsub("id:8", "id:depth_strider")
        nbt = nbt.gsub("id:7", "id:thorns")
        nbt = nbt.gsub("id:6", "id:aqua_infinity")
        nbt = nbt.gsub("id:5", "id:respiration")
        nbt = nbt.gsub("id:4", "id:projectile_protection")
        nbt = nbt.gsub("id:3", "id:blast_protection")
        nbt = nbt.gsub("id:2", "id:feather_falling")
        nbt = nbt.gsub("id:1", "id:fire_protection")
        nbt = nbt.gsub("id:0", "id:protection")
        nbt
      end

      def player_effect source, target, effect, seconds = nil, amplifier = nil, particles = false
        if effect.to_s == "clear"
          return $mcl.server.invoke do |cmd|
            cmd.default "/execute #{source} ~ ~ ~ effect #{target} clear"
            cmd.since "1.13", "17w45a", "/execute as #{source} at #{target} run effect clear #{target}"
          end
        end
        cmd = nil
        version_switch do |v|
          v.default { cmd = "/execute #{source} ~ ~ ~ effect #{target} #{effect}" }
          v.since("1.13", "17w45a") { cmd = "/execute as #{source} at #{target} run effect give #{target} #{effect}" }
        end
        if seconds
          cmd << " #{seconds}"
          if amplifier
            cmd << " #{amplifier} #{!particles}"
          end
        end
        $mcl.server.invoke(cmd)
      end

      def replace_item target, slot, item, nbt = nil
        $mcl.server.invoke do |cmd|
          cmd.default "/replaceitem entity #{target} slot.#{slot} #{item} 1 0 #{nbt}".strip
          cmd.since "1.13", "17w45a", "/replaceitem entity #{target} #{slot} #{item}#{fix_nbt nbt}".strip
        end
      end

      def give_item target, item, amount, nbt = nil
        $mcl.server.invoke do |cmd|
          cmd.default "/give #{target} #{item} #{amount} 0 #{nbt}".strip
          cmd.since "1.13", "17w45a", "/give #{target} #{item}#{fix_nbt nbt} #{amount}".strip
        end
      end
    end
    include Helper
  end
end
