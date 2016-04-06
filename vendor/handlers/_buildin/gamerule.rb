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
  # !tickspeed [ticks]
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
      # commandBlockOutput
      register_command(:cbspam, desc: "activates commandBlockOutput", acl: acl_level) { gamerule("commandBlockOutput", true) }
      register_command(:nocbspam, :cbnospam, desc: "deactivates commandBlockOutput", acl: acl_level) { gamerule("commandBlockOutput", false) }

      # mobGriefing
      register_command(:grief, desc: "activates mobGriefing", acl: acl_level) { gamerule("mobGriefing", true) }
      register_command(:nogrief, desc: "deactivates mobGriefing", acl: acl_level) { gamerule("mobGriefing", false) }

      # doFireTick
      register_command(:firetick, :firespread, desc: "deactivates doFireTick", acl: acl_level) { gamerule("doFireTick", true) }
      register_command(:nofiretick, :nofirespread, :firealarm, desc: "activates doFireTick", acl: acl_level) { gamerule("doFireTick", false) }

      # doMobLoot
      register_command(:loot, desc: "activates doMobLoot", acl: acl_level) { gamerule("doMobLoot", true) }
      register_command(:noloot, desc: "deactivates doMobLoot", acl: acl_level) { gamerule("doMobLoot", false) }

      # doTileDrops
      register_command(:drops, desc: "activates doTileDrops", acl: acl_level) { gamerule("doTileDrops", true) }
      register_command(:nodrops, desc: "deactivates doTileDrops", acl: acl_level) { gamerule("doTileDrops", false) }

      # keepInventory
      register_command(:keepinv, desc: "activates keepInventory", acl: acl_level) { gamerule("keepInventory", true) }
      register_command(:loseinv, desc: "deactivates keepInventory", acl: acl_level) { gamerule("keepInventory", false) }

      # naturalRegeneration
      register_command(:foodregen, desc: "activates naturalRegeneration", acl: acl_level) { gamerule("naturalRegeneration", true) }
      register_command(:nofoodregen, desc: "deactivates naturalRegeneration", acl: acl_level) { gamerule("naturalRegeneration", false) }

      # doMobSpawning
      register_command(:mobspawn, :mobspawning, :mobspawns, desc: "activates doMobSpawning", acl: acl_level) { gamerule("doMobSpawning", true) }
      register_command(:nomobspawn, :nomobspawning, :nomobspawns, desc: "deactivates doMobSpawning", acl: acl_level) { gamerule("doMobSpawning", false) }

      # showDeathMessages
      register_command(:deathmsg, :deathmessages, desc: "activates showDeathMessages", acl: acl_level) { gamerule("showDeathMessages", true) }
      register_command(:nodeathmsg, :nodeathmessages, desc: "deactivates showDeathMessages", acl: acl_level) { gamerule("showDeathMessages", false) }

      # reduceDebugInfo
      register_command(:reducedebug, :nodebug, desc: "activates reduceDebugInfo", acl: acl_level) { gamerule("reduceDebugInfo", true) }
      register_command(:showdebug, :expanddebug, desc: "deactivates reduceDebugInfo", acl: acl_level) { gamerule("reduceDebugInfo", false) }

      # tickspeed
      register_command(:tickspeed, desc: "sets randomTickSpeed (MC default is 3)", acl: acl_level) {|player, args| gamerule("randomTickSpeed", args[0].presence) }
    end

    def register_peace acl_level
      register_command :peace, desc: "sets up a friendly world", acl: acl_level do |player, args|
        $mcl.server.invoke "/difficulty 0"
        $mcl.server.invoke "/gamerule doMobSpawning false"
        $mcl.server.invoke "/gamerule keepInventory true"
        $mcl.server.invoke "/gamerule naturalRegeneration true"
        sleep 1
        $mcl.server.invoke "/difficulty 1"
      end
    end

    def register_pussymode acl_level
      register_command :pussymode, desc: "sets up a unfriendly world for pussies :P", acl: acl_level do |player, args|
        $mcl.server.invoke "/difficulty 1"
        $mcl.server.invoke "/gamerule doMobSpawning true"
        $mcl.server.invoke "/gamerule naturalRegeneration true"
        $mcl.server.invoke "/gamerule keepInventory false"
      end
    end

    def register_diehard acl_level
      register_command :diehard, desc: "sets up an unfriendly world", acl: acl_level do |player, args|
        $mcl.server.invoke "/difficulty 3"
        $mcl.server.invoke "/gamerule doMobSpawning true"
        $mcl.server.invoke "/gamerule naturalRegeneration true"
        $mcl.server.invoke "/gamerule keepInventory false"
      end
    end

    def register_hardcore acl_level
      register_command :hardcore, desc: "sets up a hardcore world", acl: acl_level do |player, args|
        $mcl.server.invoke "/difficulty 3"
        $mcl.server.invoke "/gamerule doMobSpawning true"
        $mcl.server.invoke "/gamerule naturalRegeneration false"
        $mcl.server.invoke "/gamerule keepInventory false"
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
