module Mcl
  Mcl.reloadable(:HMclGamerule)
  ## Gamerule shortcuts
  # !cbspam
  # !nocbspam !cbnospam
  # !grief
  # !nogrief
  # !firetick !firespread
  # !nofiretick !nofirespread !firealarm
  # !loot
  # !noloot
  # !drops
  # !nodrops
  # !keepinv
  # !loseinv
  # !foodregen
  # !nofoodregen
  # !mobspawn !mobspawning !mobspawns
  # !nomobspawn !nomobspawning !nomobspawns
  # !deathmsg !deathmessages
  # !nodeathmsg !nodeathmessages
  # !reducedebug !nodebug
  # !showdebug !expanddebug
  # !tickspeed
  class HMclGamerule < Handler
    module Helper
      def gamerule rule, value
        $mcl.server.invoke %{/gamerule #{rule} #{value}}
      end
    end
    include Helper

    def setup
      register_commands
    end

    def register_commands
      # commandBlockOutput
      register_command(:cbspam, desc: "activates commandBlockOutput", acl: :admin) { gamerule("commandBlockOutput", true) }
      register_command(:nocbspam, :cbnospam, desc: "deactivates commandBlockOutput", acl: :admin) { gamerule("commandBlockOutput", false) }

      # mobGriefing
      register_command(:grief, desc: "activates mobGriefing", acl: :admin) { gamerule("mobGriefing", true) }
      register_command(:nogrief, desc: "deactivates mobGriefing", acl: :admin) { gamerule("mobGriefing", false) }

      # doFireTick
      register_command(:firetick, :firespread, desc: "deactivates doFireTick", acl: :admin) { gamerule("doFireTick", true) }
      register_command(:nofiretick, :nofirespread, :firealarm, desc: "activates doFireTick", acl: :admin) { gamerule("doFireTick", true) }

      # doMobLoot
      register_command(:loot, desc: "activates doMobLoot", acl: :admin) { gamerule("doMobLoot", true) }
      register_command(:noloot, desc: "deactivates doMobLoot", acl: :admin) { gamerule("doMobLoot", false) }

      # doTileDrops
      register_command(:drops, desc: "activates doTileDrops", acl: :admin) { gamerule("doTileDrops", true) }
      register_command(:nodrops, desc: "deactivates doTileDrops", acl: :admin) { gamerule("doTileDrops", false) }

      # keepInventory
      register_command(:keepinv, desc: "activates keepInventory", acl: :admin) { gamerule("keepInventory", true) }
      register_command(:loseinv, desc: "deactivates keepInventory", acl: :admin) { gamerule("keepInventory", false) }

      # naturalRegeneration
      register_command(:foodregen, desc: "activates naturalRegeneration", acl: :admin) { gamerule("naturalRegeneration", true) }
      register_command(:nofoodregen, desc: "deactivates naturalRegeneration", acl: :admin) { gamerule("naturalRegeneration", false) }

      # doMobSpawning
      register_command(:mobspawn, :mobspawning, :mobspawns, desc: "activates doMobSpawning", acl: :admin) { gamerule("doMobSpawning", true) }
      register_command(:nomobspawn, :nomobspawning, :nomobspawns, desc: "deactivates doMobSpawning", acl: :admin) { gamerule("doMobSpawning", false) }

      # showDeathMessages
      register_command(:deathmsg, :deathmessages, desc: "activates showDeathMessages", acl: :admin) { gamerule("showDeathMessages", true) }
      register_command(:nodeathmsg, :nodeathmessages, desc: "deactivates showDeathMessages", acl: :admin) { gamerule("showDeathMessages", false) }

      # reduceDebugInfo
      register_command(:reducedebug, :nodebug, desc: "activates reduceDebugInfo", acl: :admin) { gamerule("reduceDebugInfo", true) }
      register_command(:showdebug, :expanddebug, desc: "deactivates reduceDebugInfo", acl: :admin) { gamerule("reduceDebugInfo", false) }

      # tickspeed
      register_command(:tickspeed, desc: "sets randomTickSpeed (MC default is 3)", acl: :admin) {|player, args| gamerule("randomTickSpeed", args[0].presence) }
    end
  end
end
