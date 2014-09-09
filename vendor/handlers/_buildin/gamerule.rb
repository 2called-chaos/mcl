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

      def gr_acl
        :admin
      end
    end
    include Helper

    def setup
      register_commands
    end

    def register_commands
      # commandBlockOutput
      register_command(:cbspam, desc: "activates commandBlockOutput", acl: gr_acl) { gamerule("commandBlockOutput", true) }
      register_command(:nocbspam, :cbnospam, desc: "deactivates commandBlockOutput", acl: gr_acl) { gamerule("commandBlockOutput", false) }

      # mobGriefing
      register_command(:grief, desc: "activates mobGriefing", acl: gr_acl) { gamerule("mobGriefing", true) }
      register_command(:nogrief, desc: "deactivates mobGriefing", acl: gr_acl) { gamerule("mobGriefing", false) }

      # doFireTick
      register_command(:firetick, :firespread, desc: "deactivates doFireTick", acl: gr_acl) { gamerule("doFireTick", true) }
      register_command(:nofiretick, :nofirespread, :firealarm, desc: "activates doFireTick", acl: gr_acl) { gamerule("doFireTick", true) }

      # doMobLoot
      register_command(:loot, desc: "activates doMobLoot", acl: gr_acl) { gamerule("doMobLoot", true) }
      register_command(:noloot, desc: "deactivates doMobLoot", acl: gr_acl) { gamerule("doMobLoot", false) }

      # doTileDrops
      register_command(:drops, desc: "activates doTileDrops", acl: gr_acl) { gamerule("doTileDrops", true) }
      register_command(:nodrops, desc: "deactivates doTileDrops", acl: gr_acl) { gamerule("doTileDrops", false) }

      # keepInventory
      register_command(:keepinv, desc: "activates keepInventory", acl: gr_acl) { gamerule("keepInventory", true) }
      register_command(:loseinv, desc: "deactivates keepInventory", acl: gr_acl) { gamerule("keepInventory", false) }

      # naturalRegeneration
      register_command(:foodregen, desc: "activates naturalRegeneration", acl: gr_acl) { gamerule("naturalRegeneration", true) }
      register_command(:nofoodregen, desc: "deactivates naturalRegeneration", acl: gr_acl) { gamerule("naturalRegeneration", false) }

      # doMobSpawning
      register_command(:mobspawn, :mobspawning, :mobspawns, desc: "activates doMobSpawning", acl: gr_acl) { gamerule("doMobSpawning", true) }
      register_command(:nomobspawn, :nomobspawning, :nomobspawns, desc: "deactivates doMobSpawning", acl: gr_acl) { gamerule("doMobSpawning", false) }

      # showDeathMessages
      register_command(:deathmsg, :deathmessages, desc: "activates showDeathMessages", acl: gr_acl) { gamerule("showDeathMessages", true) }
      register_command(:nodeathmsg, :nodeathmessages, desc: "deactivates showDeathMessages", acl: gr_acl) { gamerule("showDeathMessages", false) }

      # reduceDebugInfo
      register_command(:reducedebug, :nodebug, desc: "activates reduceDebugInfo", acl: gr_acl) { gamerule("reduceDebugInfo", true) }
      register_command(:showdebug, :expanddebug, desc: "deactivates reduceDebugInfo", acl: gr_acl) { gamerule("reduceDebugInfo", false) }

      # tickspeed
      register_command(:tickspeed, desc: "sets randomTickSpeed (MC default is 3)", acl: gr_acl) {|player, args| gamerule("randomTickSpeed", args[0].presence) }
    end
  end
end
