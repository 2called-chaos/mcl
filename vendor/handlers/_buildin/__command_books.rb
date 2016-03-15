module Mcl
  Mcl.reloadable(:HCommandBooks)
  class HCommandBooks < Handler
    module Pages
      def cs_self
        p1 = command_book_page "Command Books", [
          ["» Butcher",           "Slay everything into peaces!", "!cbook butcher"],
          ["» Cheats",            "Not as cheaty as the rest!", "!cbook cheats"],
          ["» Creative",          "For the creative guys", "!cbook creative"],
          ["» Gamemode",          "Gamemode and difficulty settings", "!cbook gamemode"],
          ["» Gamerules",         "Gamerules at your fingertips", "!cbook gamerules"],
          ["» Misc / Fun",        "Time for some fun!", "!cbook misc"],
          ["» Potion Effects",    "Go crazy and try the forbidden potions!", "!cbook potion_effects"],
          ["» Warps",            "Fly away, little friend...", "!cbook warps"],
          ["» Weather / Time",    "Be Petrus, Chronos or Doctor Who!", "!cbook weather"],
          # ["» Worldbook",        "Switch between and create new worlds", "!worldbook"],
          ["» World Edit light",  "It's a light version, that's true, but you\\ncan fuck up the server with it for sure!", "!cbook worldedit"],
          ["» Schematic Builder", "Build schematics in the\\nmost terrible way possible!", "!cbook schebu"],
          ["» Snap2date",         "Keep up2date with snapshots (also\\nseems to work with pre-releases)", "!cbook snap2date"],
        ]
        p2 = command_book_page "Command Books", [
          ["» ACL",  "Hail the perms!", "!cbook acl"],
          ["» Core", "Only for staff. Seriously!", "!cbook core"],
          # ["» Save & Restore", "Save and restore worlds", "!backupbook"],
        ]
        ["Command Books", p1, p2]
      end

      def cs_gamerules
        p1 = command_book_page "CS: Gamerules", [
          ["!cbspam",     "activates commandBlockOutput"],
          ["!nocbspam",   "deactivates commandBlockOutput"],
          ["!grief",      "activates mobGriefing"],
          ["!nogrief",    "deactivates mobGriefing"],
          ["!firetick",   "deactivates doFireTick"],
          ["!nofiretick", "activates doFireTick"],
          ["!loot",       "activates doMobLoot"],
          ["!noloot",     "deactivates doMobLoot"],
          ["!drops",      "activates doTileDrops"],
          ["!nodrops",    "deactivates doTileDrops"],
          ["!keepinv",    "activates keepInventory"],
          ["!loseinv",    "deactivates keepInventory"],
          ["!foodregen",  "activates naturalRegeneration"],
        ]
        p2 = command_book_page "CS: Gamerules", [
          ["!nofoodregen", "deactivates naturalRegeneration"],
          ["!mobspawn",    "activates doMobSpawning"],
          ["!nomobspawn",  "deactivates doMobSpawning"],
          ["!deathmsg",    "activates showDeathMessages"],
          ["!nodeathmsg",  "deactivates showDeathMessages"],
          ["!reducedebug", "activates reduceDebugInfo"],
          ["!showdebug",   "deactivates reduceDebugInfo"],
          ["!tickspeed",   "sets randomTickSpeed"],
        ]

        ["CS: Gamerules", p1, p2]
      end

      def cs_weather_time
        p1 = command_book_page "CS: Weather & Time", [
          ["!sun",      "Clears the weather for 11 days"],
          ["!rain",     "Lets it rain, you may pass a duration in seconds"],
          ["!thunder",  "Lets it thunder, you may pass a duration in seconds"],
          ["!morning",  "sets the time to 0"],
          ["!day",      "sets the time to 6k"],
          ["!evening",  "sets the time to 12k"],
          ["!night",    "sets the time to 14k"],
          ["!midnight", "sets the time to 18k"],
          ["!freeze",   "freezes the time (doDaylightCycle)"],
          ["!unfreeze", "unfreezes the time (doDaylightCycle)"],
        ]
        ["CS: Weather", p1]
      end

      def cs_acl
        p1 = command_book_page "CS: ACL", [
          ["!love",        "ops you or target for MCL (no selector)"],
          ["!hate",        "deops you or target for MCL (no selector)"],
          ["!permissions", "show all known players and their perm-level"],
          ["!op",          "ops you or a target (no selectors)"],
          ["!deop",        "deops you or a target (no selectors)"],
        ]
        ["CS: ACL", p1]
      end

      def cs_gamemode
        p1 = command_book_page "CS: Gamemode", [
          ["!c", "be creative"],
          ["!s", "be mortal and die!"],
          ["!spec", "become spectator"],
          ["!peace",    "sets up a friendly world"],
          ["!diehard",  "sets up a unfriendly world"],
          ["!hardcore", "sets up a hardcore world"],
        ]
        p2 = command_book_page "CS: Gamemode", [
          ["!c @a", "all players will be creative!"],
          ["!s @a", "all players will die!"],
          ["!spec @a", "all players will just watch!"],
        ]
        ["CS: Gamemode", p1, p2]
      end

      def cs_creative
        p1 = command_book_page "CS: Creative", [
          ["!airblock", "setblocks the block below you to dirt"],
          ["!cb",       "gives you or target a command block"],
          ["!cbt",      "inventory for command block trickery"],
        ]
        ["CS: Creative", p1]
      end

      def cs_warps
        p1 = command_book_page "CS: Warps", [
          # ["!warp book",          "no, it's not Mystcraft"],
          ["!warp <name>",        "teleport to warp"],
          ["!warp set <name>",    "set/update a warp"],
          ["!warp delete <name>", "delete a warp"],
          ["!warp share <name>",  "reveal warp to target (@a by default)"],
          ["!warp list",          "list/search warps"],
        ]
        ["CS: Warps", p1]
      end

      def cs_butcher
        p1 = command_book_page "CS: Butcher", [
          ["!butcher <type> [rad]", "kills entities in a radius around you", "!butcher help"],
          ["!butcher players",      "kills players in a 50 block radius"],
          ["!butcher hostile",      "kills hostile mobs in a 50 block radius"],
          ["!butcher mobs",         "kills passive but no farm mobs in a 50 block radius"],
          ["!butcher animals",      "kills animals in a 50 block radius"],
          ["!butcher boats",        "kills boats in a 50 block radius"],
          ["!butcher minecart",     "kills all kinds of minecarts in a 50 block radius"],
          ["!butcher items",        "kills dropped items in a 50 block radius"],
          ["!butcher xp",           "kills XP orbs in a 50 block radius"],
          ["!butcher tnt",          "kills primed TNT in a 50 block radius"],
          ["!butcher arrows",       "kills arrows in a 50 block radius"],
          ["!butcher projectiles",  "kills arrows and other projectiles in a 50 block radius"],
        ]
        ["CS: Butcher", p1]
      end

      def cs_core
        p1 = command_book_page "CS: Core", [
          ["!version",           "shows you the MC and MCL version"],
          ["!danger",            "enable danger mode for you to bypass security limits"],
          ["!backup",            "creates a backup of the world directory"],
          ["!stop",              "stops MCL and with it the server (will restart when daemonized)"],
          ["!stopmc",            "sends /stop to server which will reboot MCL and MC"],
          ["!mclupdate",         "updates and reloads MCL via git"],
          ["!mclupdate restart", "updates and restarts MCL via git"],
          ["!mclreload",         "reloads handlers and commands"],
          ["!mclreboot",         "reboots MCL (does not reload core!)"],
          ["!mclshell",          "ONLY FOR DEVELOPMENT (will freeze MCL)"],
        ]
        ["CS: Core", p1]
      end

      def cs_schebu
        p1 = command_book_page "CS: Schebu", [
          ["!schebu",                  "schematic builder"],
          ["!schebu book",             "gives you a book with more info"],
          ["!schebu add",              "add a remote schematic"],
          ["!schebu list [filter]",    "list available schematics", "!schebu list"],
          ["!schebu load <name>",      "load schematic from library", "!schebu load"],
          ["!schebu rotate <±deg>",    "rotate the schematic", "!schebu rotate"],
          ["!schebu air <t/f>",        "copy air yes or no", "!schebu air"],
          ["!schebu pos",              "set build start position"],
          ["!schebu ipos [i]",         "indicate build area", "!schebu ipos"],
          ["!schebu status",           "show info about the current build settings"],
          ["!schebu reset",            "clear your current build settings"],
          ["!schebu build",            "parse schematic and build it"],
        ]
        ["CS: Schebu", p1]
      end

      def cs_snap2date
        p1 = command_book_page "CS: Snap2date", [
          ["!snap2date status",  "list watched versions and watch status"],
          ["!snap2date check",   "check for [ver] or all watched versions"],
          ["!snap2date watch",   "start watching <ver>"],
          ["!snap2date unwatch", "stop watching <ver>"],
          ["!snap2date update",  "update to <ver>"],
          ["!snap2date cron",    "check versions all 250 ticks"],
          ["!snap2date uncron",  "stop checking versions all 250 ticks"],
        ]
        ["CS: Snap2date", p1]
      end

      def cs_cheats
        p1 = command_book_page "CS: Cheats", [
          ["!balls",    "gives you 16 ender perls"],
          ["!boat",     "summons a boat above your head"],
          ["!minecart", "summons a minecart above your head"],
          ["!airblock", "setblocks the block below you to dirt"],
          ["!l0",       "removes all levels from you"],
          ["!l30",      "adds 30 levels to you"],
          ["!l1337",    "sets your level to 1337"],
          ["!uwater",   "gives you OP underwater buffs"],
        ]
        ["CS: Cheats", p1]
      end

      def cs_misc
        p1 = command_book_page "CS: Misc / Fun", [
          ["!help",        "haha, this command is so funny!"],
          ["!rec",         "plays music discs"],
          ["!idea",        "you had an idea!"],
          ["!strike",      "strikes you with lightning"],
          ["!longwaydown", "sends you to leet height!"],
          ["!head",        "replaces your helm with a player's head"],
          ["!muuhhh",      "muuuuhhhhhh....."],
          ["!id",          "shows you the new block name for an old block ID"],
          ["!colors",      "shows all available colors"],
          ["!commands",    "searches for commands (!commands mcl)"],
        ]
        ["CS: Misc / Fun", p1]
      end
      alias_method :cs_fun, :cs_misc

      def cs_potion_effects
        p1 = command_book_page "CS: Potion Effects", [
          ["!ce",            "clears all your effects"],
          ["!qh",            "gives you 255x regen and saturation for 3 seconds"],
          ["!qj",            "gives you 5x jump boost for 3 seconds"],
          ["!idontwannadie", "gives you several OP buffs"],
          ["!immortal",      "gives you total OP buffs"],
          ["!quick",         "gives you 5x speed"],
          ["!jump",          "gives you 5x jump boost"],
          ["!feed",          "gives you 255x saturation"],
          ["!heal",          "gives you 255x regen for 60s"],
          ["!nvision",       "gives you 255x nightvision"],
          ["!breath",        "gives you 255x water breathing"],
          ["!drugs",         "gives you 255x neusea for 30s"],
          ["!onehit",        "gives you 255x strength"],
        ]
        p2 = command_book_page "CS: Potion Effects", [
          ["!fast",          "gives you 10x speed"],
          ["!faster",        "gives you 20x speed"],
          ["!gonzales",      "gives you 50x speed"],
          ["!bunny",         "gives you 10x jump boost"],
          ["!higher",        "gives you 20x jump boost"],
          ["!rocket",        "gives you 50x jump boost"],
          ["!2damoon",       "gives you 125x jump boost"],
          ["!haste",         "gives you 10x haste"],
          ["!haste2",        "gives you 255x haste"],
          ["!miningf",       "gives you 10x mining fatigue"],
          ["!strength",      "gives you 5x strength"],
          ["!resist",        "gives you 255x resistance"],
          ["!junkie",        "gives you 255x nausea"],
        ]
        p3 = command_book_page "CS: Potion Effects", [
          ["!hungry",        "gives you 255x saturation for 60s"],
          ["!starve",        "gives you 120x hunger for 30s"],
          ["!hearts",        "gives you 255x absorption"],
          ["!<3",            "gives you 255x absorption for 60s"],
          ["!slowmo",        "gives you slowmotion for 60s"],
        ]
        ["CS: Potion Effects", p1, p2, p3]
      end

      def cs_worldedit
        p1 = command_book_page "CS: World Edit light", [
          ["!!sel",     "shows or clears (!!sel clear) current selection"],
          ["!!isel",    "indicate current selection with particles"],
          ["!!set",     "fills selection with given block"],
          ["!!outline", "outlines selection with given block"],
          ["!!hollow",  "hollow selection with given block"],
          ["!!fill",    "fill air blocks in selection with given block"],
          ["!!replace", "replace b1 in selection with given b2"],
          ["!!insert",  "inserts selection at given coords"],
          ["!!stack",   "NotImplemented: stacks selection"],
        ]
        p2 = command_book_page "CS: World Edit light", [
          ["!!pos",   "sets pos1&2 to given coords"],
          ["!!spos",  "shifts pos1 and pos2 by given values"],
          ["!!ipos",  "indicate pos1 and pos2 with partic,les"],
          ["!!pos1",  "sets pos1 to given coords"],
          ["!!spos1", "shifts pos1 by given values"],
          ["!!ipos1", "indicate pos1 with particles"],
          ["!!pos2",  "sets pos2 to given coords"],
          ["!!spos2", "shifts pos2 by given values"],
          ["!!ipos2", "indicate pos2 with particles"],
        ]
        ["CS: World Edit light", p1, p2]
      end
      alias_method :cs_weather, :cs_weather_time
      alias_method :cs_time, :cs_weather_time
    end
    include Pages

    def book_list
      %w[self weather time gamerules worldedit acl gamemode potion_effects cheats misc fun core creative butcher schebu snap2date warps]
    end

    def title
      {text: "[CBook] ", color: "light_purple"}
    end

    def tellm p, *msg
      trawm(p, *([title] + msg))
    end

    def command_line cmd, desc, cmd2 = nil
      %q{{"text":"%CMD%\n", "color":"dark_green", "hoverEvent":{"action": "show_text", "value": "%DESC%"}, "clickEvent":{"action": "suggest_command", "value": "%CMD2%"}}}.gsub("%CMD%", cmd).gsub("%CMD2%", cmd2 || cmd).gsub("%DESC%", desc)
    end

    def command_book_page title, strs
      [].tap do |r|
        r << %q{{"text":"%TITLE%\n", "underlined": true, "bold": true, "color": "red"}}.gsub("%TITLE%", title)
        strs.each {|*a| r << command_line(*a.flatten)}
      end.join("\n")
    end

    def cbook who, which, opts = {}
      data = send("cs_#{which}")
      $mcl.server.invoke book(who, data.shift, data, opts)
    end

    def setup
      setup_parsers
    end

    def setup_parsers
      register_command :cbook, desc: "Handy command books for lazy lads" do |handler, player, command, target, args, optparse|
        handler.acl_verify(player)
        book = args.shift.presence
        target = args.shift.presence || player

        if book_list.include?(book.to_s)
          cbook(target, book)
        else
          handler.tellm(player, {text: "Available books: ", color: "gold"}, {text: book_list.join(", "), color: "aqua"})
        end
      end
    end
  end
end
