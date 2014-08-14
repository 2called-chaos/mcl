module Mcl
  Mcl.reloadable(:HGamerule)
  class HGamerule < Handler
    def setup
      setup_parsers
    end

    def setup_parsers
      # commandBlockOutput
      register_command(:cbspam) {|h, p, c, t, o| h.acl_verify(p) ; h.gamerule("commandBlockOutput", true) }
      register_command(:nocbspam, :cbnospam) {|h, p, c, t, o| h.acl_verify(p) ; h.gamerule("commandBlockOutput", false) }

      # mobGriefing
      register_command(:grief) {|h, p, c, t, o| h.acl_verify(p) ; h.gamerule("mobGriefing", true) }
      register_command(:nogrief) {|h, p, c, t, o| h.acl_verify(p) ; h.gamerule("mobGriefing", false) }

      # doFireTick
      register_command(:firetick, :firespread) {|h, p, c, t, o| h.acl_verify(p) ; h.gamerule("doFireTick", true) }
      register_command(:nofiretick, :nofirespread, :firealarm) {|h, p, c, t, o| h.acl_verify(p) ; h.gamerule("doFireTick", true) }

      # doMobLoot
      register_command(:loot) {|h, p, c, t, o| h.acl_verify(p) ; h.gamerule("doMobLoot", true) }
      register_command(:noloot) {|h, p, c, t, o| h.acl_verify(p) ; h.gamerule("doMobLoot", false) }

      # doTileDrops
      register_command(:drops) {|h, p, c, t, o| h.acl_verify(p) ; h.gamerule("doTileDrops", true) }
      register_command(:nodrops) {|h, p, c, t, o| h.acl_verify(p) ; h.gamerule("doTileDrops", false) }

      # keepInventory
      register_command(:keepinv) {|h, p, c, t, o| h.acl_verify(p) ; h.gamerule("keepInventory", true) }
      register_command(:loseinv) {|h, p, c, t, o| h.acl_verify(p) ; h.gamerule("keepInventory", false) }

      # naturalRegeneration
      register_command(:foodregen) {|h, p, c, t, o| h.acl_verify(p) ; h.gamerule("naturalRegeneration", true) }
      register_command(:nofoodregen) {|h, p, c, t, o| h.acl_verify(p) ; h.gamerule("naturalRegeneration", false) }

      # doMobSpawning
      register_command(:mobspawn, :mobspawning, :mobspawns) {|h, p, c, t, o| h.acl_verify(p) ; h.gamerule("doMobSpawning", true) }
      register_command(:nomobspawn, :nomobspawning, :nomobspawns) {|h, p, c, t, o| h.acl_verify(p) ; h.gamerule("doMobSpawning", false) }

      # showDeathMessages
      register_command(:deathmsg, :deathmessages) {|h, p, c, t, o| h.acl_verify(p) ; h.gamerule("showDeathMessages", true) }
      register_command(:nodeathmsg, :nodeathmessages) {|h, p, c, t, o| h.acl_verify(p) ; h.gamerule("showDeathMessages", false) }

      # reduceDebugInfo
      register_command(:reducedebug, :nodebug) {|h, p, c, t, o| h.acl_verify(p) ; h.gamerule("reduceDebugInfo", true) }
      register_command(:showdebug, :expanddebug) {|h, p, c, t, o| h.acl_verify(p) ; h.gamerule("reduceDebugInfo", false) }

      # tickspeed
      register_command :tickspeed do |handler, player, command, target, optparse|
        handler.acl_verify(player)
        handler.gamerule("randomTickSpeed", command.split(" ")[1].presence)
      end
    end

    def gamerule rule, value
      $mcl.server.invoke %{/gamerule #{rule} #{value}}
    end
  end
end
