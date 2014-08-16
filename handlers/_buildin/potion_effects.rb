module Mcl
  Mcl.reloadable(:HPotionEffects)
  class HPotionEffects < Handler
    def setup
      setup_parsers
    end

    def setup_parsers
      register_command(:ce, :milk, desc: "clears all your or target's effects") {|h, p, c, t, o| h.effect(t, "clear") }

      # speed
      register_command(:quick, :speed, desc: "gives you or target 5x speed") {|h, p, c, t, o| h.effect(t, "speed", 6000, 5) }
      register_command(:fast, desc: "gives you or target 10x speed") {|h, p, c, t, o| h.effect(t, "speed", 6000, 10) }
      register_command(:faster, desc: "gives you or target 20x speed") {|h, p, c, t, o| h.effect(t, "speed", 6000, 20) }
      register_command(:gonzales, desc: "gives you or target 50x speed") {|h, p, c, t, o| h.effect(t, "speed", 6000, 50) }

      # jump
      register_command(:qj, desc: "gives you or target 5x jump boost for 3 seconds") {|h, p, c, t, o| h.effect(t, "jump_boost", 3, 5, true) }
      register_command(:jump, desc: "gives you or target 5x jump boost") {|h, p, c, t, o| h.effect(t, "jump_boost", 6000, 5) }
      register_command(:bunny, desc: "gives you or target 10x jump boost") {|h, p, c, t, o| h.effect(t, "jump_boost", 6000, 10) }
      register_command(:higher, desc: "gives you or target 20x jump boost") {|h, p, c, t, o| h.effect(t, "jump_boost", 6000, 20) }
      register_command(:rocket, desc: "gives you or target 50x jump boost") {|h, p, c, t, o| h.effect(t, "jump_boost", 6000, 50) }
      register_command(:"2damoon", desc: "gives you or target 125x jump boost") {|h, p, c, t, o| h.effect(t, "jump_boost", 6000, 125) }

      # haste
      register_command(:haste, desc: "gives you or target 10x haste") {|h, p, c, t, o| h.effect(t, "haste", 6000, 10) }
      register_command(:haste2, desc: "gives you or target 255x haste") {|h, p, c, t, o| h.effect(t, "haste", 6000, 255) }

      # minin fatuege
      register_command(:miningf, desc: "gives you or target 10x mining fatigue") {|h, p, c, t, o| h.effect(t, "mining_fatigue", 6000, 10) }

      # night vision
      register_command(:nvision, :nightvision, :night_vision, :letitbelight, desc: "gives you or target 255x nightvision") {|h, p, c, t, o| h.effect(t, "night_vision", 6000, 255) }

      # strength
      register_command(:strength, desc: "gives you or target 5x strength") {|h, p, c, t, o| h.effect(t, "strength", 6000, 5) }
      register_command(:onehit, desc: "gives you or target 255x strength") {|h, p, c, t, o| h.effect(t, "strength", 6000, 255) }

      # regeneration
      register_command(:qh, desc: "gives you or target 255x regen and saturation for 3 seconds") {|h, p, c, t, o| h.effect(t, "regeneration", 3, 255, true) ; h.effect(t, "saturation", 3, 255, true) }
      register_command(:heal, desc: "gives you or target 255x regen for 60s") {|h, p, c, t, o| h.effect(t, "regeneration", 60, 255) }

      # resistance
      register_command(:resist, desc: "gives you or target 255x resistance") {|h, p, c, t, o| h.effect(t, "resistance", 6000, 255) }

      # water breathing
      register_command(:breath, desc: "gives you or target 255x water breathing") {|h, p, c, t, o| h.effect(t, "water_breathing", 6000, 255) }

      # nausea
      register_command(:drugs, desc: "gives you or target 255x neusea for 30s") {|h, p, c, t, o| h.effect(t, "nausea", 30, 255) }
      register_command(:junkie, desc: "gives you or target 255x nausea") {|h, p, c, t, o| h.effect(t, "nausea", 6000, 255) }

      # feed
      register_command(:hungry, desc: "gives you or target 255x saturation for 60s") {|h, p, c, t, o| h.effect(t, "saturation", 60, 255) }
      register_command(:feed, desc: "gives you or target 255x saturation") {|h, p, c, t, o| h.effect(t, "saturation", 6000, 255) }

      # starve
      register_command(:starve, desc: "gives you or target 120x hunger for 30s") {|h, p, c, t, o| h.effect(t, "hunger", 120, 30) }


      # misc
      register_command(:hearts, desc: "gives you or target 255x absorption") {|h, p, c, t, o| h.effect(t, "absorption", 6000, 255) }
      register_command(:"<3", desc: "gives you or target 255x absorption for 60s") {|h, p, c, t, o| h.effect(t, "absorption", 60, 255) }
      register_command(:idontwannadie, desc: "gives you or target several OP buffs") do |h, p, c, t, o|
        h.effect(t, "regeneration", 6000, 255)
        h.effect(t, "resistance", 6000, 255)
        h.effect(t, "strength", 6000, 255)
        h.effect(t, "absorption", 6000, 4)
      end
      register_command(:slowmo, :matrix, desc: "gives you or target slowmotion for 60s") do |h, p, c, t, o|
        h.effect(t, "slowness", 60, 4)
        h.effect(t, "mining_fatigue", 60, 60)
      end
      register_command(:immortal, desc: "gives you or target total OP buffs") do |h, p, c, t, o|
        h.effect(t, "speed", 6000, 5)
        h.effect(t, "jump_boost", 6000, 3)
        h.effect(t, "regeneration", 6000, 255)
        h.effect(t, "resistance", 6000, 255)
        h.effect(t, "strength", 6000, 255)
        h.effect(t, "absorption", 6000, 4)
        h.effect(t, "saturation", 6000, 4)
        h.effect(t, "haste", 6000, 5)
        h.effect(t, "night_vision", 6000, 255)
      end
      register_command(:uwater, desc: "gives you or target OP underwater buffs") do |h, p, c, t, o|
        h.effect(t, "water_breathing", 6000, 255)
        h.effect(t, "night_vision", 6000, 255)
        h.effect(t, "speed", 6000, 10)
        h.ritem(t, "armor.head", "diamond_helmet 1 0 {ench:[{id:0,lvl:1337},{id:6,lvl:1337}],Unbreakable:1}")
        h.ritem(t, "armor.chest", "diamond_chestplate 1 0 {ench:[{id:0,lvl:1337},{id:7,lvl:1337}],Unbreakable:1}")
        h.ritem(t, "armor.legs", "diamond_leggings 1 0 {ench:[{id:0,lvl:1337},{id:7,lvl:1337}],Unbreakable:1}")
        h.ritem(t, "armor.feet", "diamond_boots 1 0 {ench:[{id:0,lvl:1337},{id:7,lvl:1337},{id:8,lvl:3}],Unbreakable:1}")
      end
    end

    def effect target, effect, seconds = nil, amplifier = nil, particles = false
      cmd = "/effect #{target} #{effect}"
      if seconds
        cmd << " #{seconds}"
        if amplifier
          cmd << " #{amplifier} #{!particles}"
        end
      end
      $mcl.server.invoke(cmd)
    end

    def ritem target, slot, item
      $mcl.server.invoke("/replaceitem entity #{target} slot.#{slot} #{item}")
    end
  end
end
