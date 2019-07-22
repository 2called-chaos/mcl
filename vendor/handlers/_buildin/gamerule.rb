module Mcl
  Mcl.reloadable(:HMclGamerule)
  ## Gamerule shortcuts
  # !showadv
  # !hideadv !noadv !advspam !cbnospam
  # !cbspam
  # !nocbspam !cbnospam
  # !checkelytra
  # !nocheckelytra
  # !edrops
  # !noedrops
  # !firetick !firespread
  # !nofiretick !nofirespread !firealarm
  # !limitedcrafting
  # !fullcrafting
  # !loot
  # !noloot
  # !mobspawn !mobspawning !mobspawns
  # !nomobspawn !nomobspawning !nomobspawns
  # !drops
  # !nodrops
  # !keepinv
  # !loseinv
  # !dolog
  # !nolog
  # !maxentities !maxent !maxents [num]
  # !grief
  # !nogrief
  # !foodregen
  # !nofoodregen
  # !tickspeed [ticks]
  # !reducedebug !nodebug
  # !showdebug !expanddebug
  # !sendfeedback
  # !nofeedback
  # !deathmsg !deathmessages
  # !nodeathmsg !nodeathmessages
  # !spawnradius [radius]
  # !specgen
  # !nospecgen
  # !peace
  # !pussymode
  # !diehard
  # !hardcore
  class HMclGamerule < Handler
    def setup
      register_commands :admin
      register_peace :admin
      register_pussymode :admin
      register_diehard :admin
      register_hardcore :admin
    end

    def register_commands acl_level
      # announceAdvancements
      register_command(:showadv, desc: "activates announceAdvancements", acl: acl_level) { gamerule("announceAdvancements", true) }
      register_command(:hideadv, :noadv, :advspam, :cbnospam, desc: "deactivates announceAdvancements", acl: acl_level) { gamerule("announceAdvancements", false) }

      # commandBlockOutput
      register_command(:cbspam, desc: "activates commandBlockOutput", acl: acl_level) { gamerule("commandBlockOutput", true) }
      register_command(:nocbspam, :cbnospam, desc: "deactivates commandBlockOutput", acl: acl_level) { gamerule("commandBlockOutput", false) }

      # disableElytraMovementCheck
      register_command(:checkelytra, desc: "deactivates disableElytraMovementCheck", acl: acl_level) { gamerule("disableElytraMovementCheck", false) }
      register_command(:nocheckelytra, desc: "activates disableElytraMovementCheck", acl: acl_level) { gamerule("disableElytraMovementCheck", true) }

      # doEntityDrops
      register_command(:edrops, desc: "activates doEntityDrops", acl: acl_level) { gamerule("doEntityDrops", true) }
      register_command(:noedrops, desc: "deactivates doEntityDrops", acl: acl_level) { gamerule("doEntityDrops", false) }

      # doFireTick
      register_command(:firetick, :firespread, desc: "deactivates doFireTick", acl: acl_level) { gamerule("doFireTick", true) }
      register_command(:nofiretick, :nofirespread, :firealarm, desc: "activates doFireTick", acl: acl_level) { gamerule("doFireTick", false) }

      # doLimitedCrafting
      register_command(:limitedcrafting, desc: "deactivates doLimitedCrafting", acl: acl_level) { gamerule("doLimitedCrafting", true) }
      register_command(:fullcrafting, desc: "activates doLimitedCrafting", acl: acl_level) { gamerule("doLimitedCrafting", false) }

      # doMobLoot
      register_command(:loot, desc: "activates doMobLoot", acl: acl_level) { gamerule("doMobLoot", true) }
      register_command(:noloot, desc: "deactivates doMobLoot", acl: acl_level) { gamerule("doMobLoot", false) }

      # doMobSpawning
      register_command(:mobspawn, :mobspawning, :mobspawns, desc: "activates doMobSpawning", acl: acl_level) { gamerule("doMobSpawning", true) }
      register_command(:nomobspawn, :nomobspawning, :nomobspawns, desc: "deactivates doMobSpawning", acl: acl_level) { gamerule("doMobSpawning", false) }

      # doTileDrops
      register_command(:drops, desc: "activates doTileDrops", acl: acl_level) { gamerule("doTileDrops", true) }
      register_command(:nodrops, desc: "deactivates doTileDrops", acl: acl_level) { gamerule("doTileDrops", false) }

      # keepInventory
      register_command(:keepinv, desc: "activates keepInventory", acl: acl_level) { gamerule("keepInventory", true) }
      register_command(:loseinv, desc: "deactivates keepInventory", acl: acl_level) { gamerule("keepInventory", false) }

      # logAdminCommands
      register_command(:dolog, desc: "activates logAdminCommands", acl: acl_level) { gamerule("logAdminCommands", true) }
      register_command(:nolog, desc: "deactivates logAdminCommands", acl: acl_level) { gamerule("logAdminCommands", false) }

      # maxEntityCramming
      register_command(:maxentities, :maxent, :maxents, desc: "sets maxEntityCramming (MC default is 24)", acl: acl_level) {|player, args| gamerule("maxEntityCramming", args[0].presence) }

      # mobGriefing
      register_command(:grief, desc: "activates mobGriefing", acl: acl_level) { gamerule("mobGriefing", true) }
      register_command(:nogrief, desc: "deactivates mobGriefing", acl: acl_level) { gamerule("mobGriefing", false) }

      # naturalRegeneration
      register_command(:foodregen, desc: "activates naturalRegeneration", acl: acl_level) { gamerule("naturalRegeneration", true) }
      register_command(:nofoodregen, desc: "deactivates naturalRegeneration", acl: acl_level) { gamerule("naturalRegeneration", false) }

      # tickspeed
      register_command(:tickspeed, desc: "sets randomTickSpeed (MC default is 3)", acl: acl_level) {|player, args| gamerule("randomTickSpeed", args[0].presence) }

      # reduceDebugInfo
      register_command(:reducedebug, :nodebug, desc: "activates reduceDebugInfo", acl: acl_level) { gamerule("reduceDebugInfo", true) }
      register_command(:showdebug, :expanddebug, desc: "deactivates reduceDebugInfo", acl: acl_level) { gamerule("reduceDebugInfo", false) }

      # sendCommandFeedback
      register_command(:sendfeedback, desc: "activates sendCommandFeedback", acl: acl_level) { gamerule("sendCommandFeedback", true) }
      register_command(:nofeedback, desc: "deactivates sendCommandFeedback", acl: acl_level) { gamerule("sendCommandFeedback", false) }

      # showDeathMessages
      register_command(:deathmsg, :deathmessages, desc: "activates showDeathMessages", acl: acl_level) { gamerule("showDeathMessages", true) }
      register_command(:nodeathmsg, :nodeathmessages, desc: "deactivates showDeathMessages", acl: acl_level) { gamerule("showDeathMessages", false) }

      # spawnRadius
      register_command(:spawnradius, desc: "sets spawnRadius (MC default is 10)", acl: acl_level) {|player, args| gamerule("spawnRadius", args[0].presence) }

      # spectatorsGenerateChunks
      register_command(:specgen, desc: "activates spectatorsGenerateChunks", acl: acl_level) { gamerule("spectatorsGenerateChunks", true) }
      register_command(:nospecgen, desc: "deactivates spectatorsGenerateChunks", acl: acl_level) { gamerule("spectatorsGenerateChunks", false) }
    end

    def register_peace acl_level
      register_command :peace, desc: "sets up a friendly world", acl: acl_level do |player, args|
        $mcl.server.invoke "/difficulty peaceful"
        gamerule "doMobSpawning", false
        gamerule "keepInventory", true
        gamerule "naturalRegeneration", true
        sleep 1
        $mcl.server.invoke "/difficulty normal"
      end
    end

    def register_pussymode acl_level
      register_command :pussymode, desc: "sets up a unfriendly world for pussies :P", acl: acl_level do |player, args|
        $mcl.server.invoke "/difficulty normal"
        gamerule "doMobSpawning", true
        gamerule "naturalRegeneration", true
        gamerule "keepInventory", false
      end
    end

    def register_diehard acl_level
      register_command :diehard, desc: "sets up an unfriendly world", acl: acl_level do |player, args|
        $mcl.server.invoke "/difficulty hard"
        gamerule "doMobSpawning", true
        gamerule "naturalRegeneration", true
        gamerule "keepInventory", false
      end
    end

    def register_hardcore acl_level
      register_command :hardcore, desc: "sets up a hardcore world", acl: acl_level do |player, args|
        $mcl.server.invoke "/difficulty hard"
        gamerule "doMobSpawning", true
        gamerule "naturalRegeneration", false
        gamerule "keepInventory", false
      end
    end

    module Helper
      def gamerule rule, value
        $mcl.server.invoke %{/gamerule #{rule} #{value}}
      end
    end
    include Helper
  end
end
