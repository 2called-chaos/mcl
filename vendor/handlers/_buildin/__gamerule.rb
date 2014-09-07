module Mcl
  Mcl.reloadable(:HGamerule)
  class HGamerule < Handler
    def setup
      setup_parsers
    end

    def setup_parsers
      # commandBlockOutput
      register_command(:cbspam, desc: "activates commandBlockOutput") {|h, p, c, t, a, o| h.acl_verify(p) ; h.gamerule("commandBlockOutput", true) }
      register_command(:nocbspam, :cbnospam, desc: "deactivates commandBlockOutput") {|h, p, c, t, a, o| h.acl_verify(p) ; h.gamerule("commandBlockOutput", false) }

      # mobGriefing
      register_command(:grief, desc: "activates mobGriefing") {|h, p, c, t, a, o| h.acl_verify(p) ; h.gamerule("mobGriefing", true) }
      register_command(:nogrief, desc: "deactivates mobGriefing") {|h, p, c, t, a, o| h.acl_verify(p) ; h.gamerule("mobGriefing", false) }

      # doFireTick
      register_command(:firetick, :firespread, desc: "deactivates doFireTick") {|h, p, c, t, a, o| h.acl_verify(p) ; h.gamerule("doFireTick", true) }
      register_command(:nofiretick, :nofirespread, :firealarm, desc: "activates doFireTick") {|h, p, c, t, a, o| h.acl_verify(p) ; h.gamerule("doFireTick", true) }

      # doMobLoot
      register_command(:loot, desc: "activates doMobLoot") {|h, p, c, t, a, o| h.acl_verify(p) ; h.gamerule("doMobLoot", true) }
      register_command(:noloot, desc: "deactivates doMobLoot") {|h, p, c, t, a, o| h.acl_verify(p) ; h.gamerule("doMobLoot", false) }

      # doTileDrops
      register_command(:drops, desc: "activates doTileDrops") {|h, p, c, t, a, o| h.acl_verify(p) ; h.gamerule("doTileDrops", true) }
      register_command(:nodrops, desc: "deactivates doTileDrops") {|h, p, c, t, a, o| h.acl_verify(p) ; h.gamerule("doTileDrops", false) }

      # keepInventory
      register_command(:keepinv, desc: "activates keepInventory") {|h, p, c, t, a, o| h.acl_verify(p) ; h.gamerule("keepInventory", true) }
      register_command(:loseinv, desc: "deactivates keepInventory") {|h, p, c, t, a, o| h.acl_verify(p) ; h.gamerule("keepInventory", false) }

      # naturalRegeneration
      register_command(:foodregen, desc: "activates naturalRegeneration") {|h, p, c, t, a, o| h.acl_verify(p) ; h.gamerule("naturalRegeneration", true) }
      register_command(:nofoodregen, desc: "deactivates naturalRegeneration") {|h, p, c, t, a, o| h.acl_verify(p) ; h.gamerule("naturalRegeneration", false) }

      # doMobSpawning
      register_command(:mobspawn, :mobspawning, :mobspawns, desc: "activates doMobSpawning") {|h, p, c, t, a, o| h.acl_verify(p) ; h.gamerule("doMobSpawning", true) }
      register_command(:nomobspawn, :nomobspawning, :nomobspawns, desc: "deactivates doMobSpawning") {|h, p, c, t, a, o| h.acl_verify(p) ; h.gamerule("doMobSpawning", false) }

      # showDeathMessages
      register_command(:deathmsg, :deathmessages, desc: "activates showDeathMessages") {|h, p, c, t, a, o| h.acl_verify(p) ; h.gamerule("showDeathMessages", true) }
      register_command(:nodeathmsg, :nodeathmessages, desc: "deactivates showDeathMessages") {|h, p, c, t, a, o| h.acl_verify(p) ; h.gamerule("showDeathMessages", false) }

      # reduceDebugInfo
      register_command(:reducedebug, :nodebug, desc: "activates reduceDebugInfo") {|h, p, c, t, a, o| h.acl_verify(p) ; h.gamerule("reduceDebugInfo", true) }
      register_command(:showdebug, :expanddebug, desc: "deactivates reduceDebugInfo") {|h, p, c, t, a, o| h.acl_verify(p) ; h.gamerule("reduceDebugInfo", false) }

      # tickspeed
      register_command :tickspeed, desc: "sets randomTickSpeed" do |handler, player, command, target, args, optparse|
        handler.acl_verify(player)
        handler.gamerule("randomTickSpeed", args[0].presence)
      end
    end

    def gamerule rule, value
      $mcl.server.invoke %{/gamerule #{rule} #{value}}
    end
  end
end
