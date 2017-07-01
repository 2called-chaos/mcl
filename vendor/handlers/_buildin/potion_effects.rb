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
        replace_item  target, "armor.head",  "diamond_helmet 1 0     {ench:[{id:0,lvl:1337},{id:6,lvl:1337}],Unbreakable:1}"
        replace_item  target, "armor.chest", "diamond_chestplate 1 0 {ench:[{id:0,lvl:1337},{id:7,lvl:1337}],Unbreakable:1}"
        replace_item  target, "armor.legs",  "diamond_leggings 1 0   {ench:[{id:0,lvl:1337},{id:7,lvl:1337}],Unbreakable:1}"
        replace_item  target, "armor.feet",  "diamond_boots 1 0      {ench:[{id:0,lvl:1337},{id:7,lvl:1337},{id:8,lvl:3}],Unbreakable:1}"
      end
      register_command(:gimme, desc: "gives you or target a perfect outfit", acl: ph_acl) do |player, args|
        target = args.first || player
        # weapons / tools
        $mcl.server.invoke %{/give #{target} diamond_sword 1 0 {display:{Name:"The Butcher",Lore:["Kills everything"]},ench:[{id:16,lvl:5},{id:21,lvl:3},{id:22,lvl:3},{id:34,lvl:3},{id:70,lvl:1}]}}
        $mcl.server.invoke %{/give #{target} bow 1 0 {display:{Name:"AK47",Lore:["Not really as good"]},ench:[{id:34,lvl:3},{id:48,lvl:5},{id:49,lvl:2},{id:50,lvl:1},{id:51,lvl:1}]}}
        $mcl.server.invoke %{/give #{target} diamond_pickaxe 1 0 {display:{Name:"PickMuch",Lore:["with luck!"]},ench:[{id:32,lvl:5},{id:34,lvl:3},{id:35,lvl:3},{id:70,lvl:1}]}}
        $mcl.server.invoke %{/give #{target} diamond_pickaxe 1 0 {display:{Name:"PickGood",Lore:["with silk!"]},ench:[{id:32,lvl:5},{id:34,lvl:3},{id:33,lvl:1},{id:70,lvl:1}]}}
        $mcl.server.invoke %{/give #{target} diamond_shovel 1 0 {display:{Name:DigIt,Lore:["dig it?"]},ench:[{id:32,lvl:5},{id:33,lvl:1},{id:34,lvl:3},{id:70,lvl:1}]}}
        $mcl.server.invoke %{/give #{target} diamond_axe 1 0 {display:{Name:"ChopChop",Lore:["Suey!"]},ench:[{id:16,lvl:5},{id:32,lvl:5},{id:34,lvl:3},{id:35,lvl:3},{id:70,lvl:1}]}}

        # items
        2.times {
          $mcl.server.invoke %{/give #{target} ender_pearl 16}
          $mcl.server.invoke %{/give #{target} fireworks 64 0 {Fireworks:{Flight:15}}}
          $mcl.server.invoke %{/give #{target} cooked_beef 64 0}
        }
        $mcl.server.invoke %{/give #{target} arrow 1 0}
        $mcl.server.invoke %{/give #{target} flint_and_steel 1 0}
        $mcl.server.invoke %{/give #{target} torch 64 0}

        # armor
        $mcl.server.invoke %{/give #{target} diamond_helmet 1 0 {display:{Name:"AntiBrainZ",Lore:["Don't let the zombies get your brain","Also works underwater"]},ench:[{id:4,lvl:4},{id:5,lvl:3},{id:6,lvl:1},{id:7,lvl:2},{id:34,lvl:3},{id:70,lvl:3}]}}
        $mcl.server.invoke %{/give #{target} diamond_chestplate 1 0 {display:{Name:"AntiPainZ",Lore:["Don't let them rip your heart!","No refund!"]},ench:[{id:0,lvl:4},{id:7,lvl:2},{id:34,lvl:3},{id:70,lvl:3}]}}
        $mcl.server.invoke %{/give #{target} diamond_leggings 1 0 {display:{Name:"AntiHotZ",Lore:["Protects you from hot incidents.","Doesn't work for chilli!"]},ench:[{id:1,lvl:4},{id:7,lvl:2},{id:34,lvl:3},{id:70,lvl:3}]}}
        $mcl.server.invoke %{/give #{target} diamond_boots 1 0 {display:{Name:"AntiSlowZ",Lore:["Run like you never did before!","With new slime technology!"]},ench:[{id:2,lvl:4},{id:3,lvl:4},{id:7,lvl:2},{id:8,lvl:3},{id:34,lvl:3},{id:70,lvl:3}]}}
        $mcl.server.invoke %{/give #{target} elytra 1 0 {display:{Name:"Jetpack",Lore:["Not really a jetpack!"]},ench:[{id:0,lvl:4},{id:7,lvl:2},{id:34,lvl:3},{id:70,lvl:3}]}}


      end
    end

    module Helper
      def ph_acl
        :mod
      end

      def ph names, effect, desc
        register_command(*[*names], desc: desc, acl: ph_acl) {|player, args| player_effect(player, args.first || player, *[*effect]) }
      end

      def player_effect source, target, effect, seconds = nil, amplifier = nil, particles = false
        cmd = "/execute #{source} ~ ~ ~ effect #{target} #{effect}"
        if seconds
          cmd << " #{seconds}"
          if amplifier
            cmd << " #{amplifier} #{!particles}"
          end
        end
        $mcl.server.invoke(cmd)
      end

      def replace_item target, slot, item
        $mcl.server.invoke("/replaceitem entity #{target} slot.#{slot} #{item}")
      end
    end
    include Helper
  end
end
