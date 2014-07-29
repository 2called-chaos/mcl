module Mcl
  Mcl.reloadable(:HPotionEffects)
  class HPotionEffects < Handler
    def setup
      setup_parsers
    end

    def setup_parsers
      register_command("ce") {|h, p, c, t, o| h.effect(t, "clear") }
      register_command("milk") {|h, p, c, t, o| h.effect(t, "clear") }

      # speed
      register_command("quick") {|h, p, c, t, o| h.effect(t, "speed", 6000, 5) }
      register_command("fast") {|h, p, c, t, o| h.effect(t, "speed", 6000, 10) }
      register_command("faster") {|h, p, c, t, o| h.effect(t, "speed", 6000, 20) }
      register_command("gonzales") {|h, p, c, t, o| h.effect(t, "speed", 6000, 50) }

      # jump
      register_command("jump") {|h, p, c, t, o| h.effect(t, "jump_boost", 6000, 5) }
      register_command("bunny") {|h, p, c, t, o| h.effect(t, "jump_boost", 6000, 10) }
      register_command("higher") {|h, p, c, t, o| h.effect(t, "jump_boost", 6000, 20) }
      register_command("rocket") {|h, p, c, t, o| h.effect(t, "jump_boost", 6000, 50) }
      register_command("2damoon") {|h, p, c, t, o| h.effect(t, "jump_boost", 6000, 125) }

      # haste
      register_command("haste") {|h, p, c, t, o| h.effect(t, "haste", 6000, 10) }
      register_command("haste2") {|h, p, c, t, o| h.effect(t, "haste", 6000, 255) }

      # minin fatuege
      register_command("miningf") {|h, p, c, t, o| h.effect(t, "mining_fatigue", 6000, 10) }

      # night vision
      register_command("nvision") {|h, p, c, t, o| h.effect(t, "night_vision", 6000, 255) }
      register_command("nightvision") {|h, p, c, t, o| h.effect(t, "night_vision", 6000, 255) }
      register_command("night_vision") {|h, p, c, t, o| h.effect(t, "night_vision", 6000, 255) }
      register_command("letitbelight") {|h, p, c, t, o| h.effect(t, "night_vision", 6000, 255) }

      # strength
      register_command("strength") {|h, p, c, t, o| h.effect(t, "strength", 6000, 5) }
      register_command("onehit") {|h, p, c, t, o| h.effect(t, "strength", 6000, 255) }

      # regeneration
      register_command("heal") {|h, p, c, t, o| h.effect(t, "regeneration", 60, 255) }

      # resistance
      register_command("resist") {|h, p, c, t, o| h.effect(t, "resistance", 6000, 255) }

      # water breathing
      register_command("breath") {|h, p, c, t, o| h.effect(t, "water_breathing", 6000, 255) }

      # nausea
      register_command("drugs") {|h, p, c, t, o| h.effect(t, "nausea", 30, 255) }
      register_command("junkie") {|h, p, c, t, o| h.effect(t, "nausea", 6000, 255) }

      # feed
      register_command("hungry") {|h, p, c, t, o| h.effect(t, "saturation", 60, 255) }
      register_command("feed") {|h, p, c, t, o| h.effect(t, "saturation", 6000, 255) }

      # starve
      register_command("starve") {|h, p, c, t, o| h.effect(t, "hunger", 120, 30) }


      # misc
      register_command("hearts") {|h, p, c, t, o| h.effect(t, "absorption", 6000, 255) }
      register_command("<3") {|h, p, c, t, o| h.effect(t, "absorption", 60, 255) }
      register_command("idontwannadie") do |h, p, c, t, o|
        h.effect(t, "regeneration", 6000, 255)
        h.effect(t, "resistance", 6000, 255)
        h.effect(t, "strength", 6000, 255)
        h.effect(t, "absorption", 6000, 4)
      end
      register_command("slowmo") do |h, p, c, t, o|
        h.effect(t, "slowness", 60, 4)
        h.effect(t, "mining_fatigue", 60, 60)
      end
      register_command("immortal") do |h, p, c, t, o|
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
      register_command("uwater") do |h, p, c, t, o|
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
