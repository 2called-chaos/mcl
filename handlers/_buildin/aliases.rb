module Mcl
  Mcl.reloadable(:HAliases)
  class HAliases < Handler
    def setup
      setup_parsers
    end

    def setup_parsers
      # ==========
      # = Cheats =
      # ==========
      register_command "iamop" do |handler, player, command, target, optparse|
        $mcl.server.msg target, "dude, #{command} hasn't been implemented yet"
      end
      register_command "iamlegend" do |handler, player, command, target, optparse|
        $mcl.server.msg target, "dude, #{command} hasn't been implemented yet"
      end
      register_command :strike, desc: "strikes you or a target with lightning" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/execute #{target} ~ ~ ~ summon LightningBolt"
      end
      register_command :boat, desc: "summons a boat above your or target's head" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/execute #{target} ~ ~ ~ summon Boat ~ ~2 ~"
      end
      register_command :longwaydown, desc: "sends you or target to leet height!" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/execute #{target} ~ ~ ~ tp @p ~ 1337 ~"
      end
      register_command :muuhhh, desc: "muuuuhhhhhh....." do |handler, player, command, target, optparse|
        handler.async do
          handler.acl_verify(player)
          $mcl.synchronize{ handler.cow(target, "~ ~50 ~") }
          sleep 3

          $mcl.synchronize{ handler.cow(target, "~ ~50 ~") }
          sleep 0.2
          $mcl.synchronize{ handler.cow(target, "~ ~50 ~") }
          sleep 3


          $mcl.synchronize{ handler.cow(target, "~ ~50 ~") }
          sleep 0.2
          $mcl.synchronize{ handler.cow(target, "~ ~50 ~") }
          sleep 0.2
          $mcl.synchronize{ handler.cow(target, "~ ~50 ~") }
          sleep 3

          $mcl.synchronize do
            100.times do
              handler.cow(target, "~ ~50 ~")
              sleep 0.05
            end
          end
        end
      end



      # ======
      # = XP =
      # ======
      register_command :l0, desc: "removes all levels from you or a target" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/xp -10000L #{target}"
      end
      register_command :l30, desc: "adds 30 levels to you or a target" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/xp 30L #{target}"
      end
      register_command :l1337, desc: "sets your or target's level to 1337" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/xp -10000L #{target}"
        $mcl.server.invoke "/xp 1337L #{target}"
      end



      # ===========
      # = Weather =
      # ===========
      register_command :sun, desc: "Clears the weather for 11 days" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/weather clear 999999"
      end
      register_command :rain, desc: "Lets it rain, you may pass a duration in seconds" do |handler, player, command, target, optparse|
        handler.acl_verify(player)
        duration = command.split(" ")[1].presence
        $mcl.server.invoke "/weather rain #{duration}"
      end
      register_command :thunder, desc: "Lets it thunder, you may pass a duration in seconds" do |handler, player, command, target, optparse|
        handler.acl_verify(player)
        duration = command.split(" ")[1].presence
        $mcl.server.invoke "/weather thunder #{duration}"
      end



      # ========
      # = Time =
      # ========
      register_command :morning, desc: "sets the time to 0" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/time set 0"
      end
      register_command :day, :noon, desc: "sets the time to 6k" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/time set 6000"
      end
      register_command :evening, desc: "sets the time to 12k" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/time set 12000"
      end
      register_command :night, desc: "sets the time to 14k" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/time set 14000"
      end
      register_command :midnight, desc: "sets the time to 18k" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/time set 18000"
      end
      register_command :freeze, desc: "freezes the time (doDaylightCycle)" do |handler, player, command, target, optparse|
        handler.acl_verify(player)
        $mcl.server.invoke "/gamerule doDaylightCycle false"
      end
      register_command :unfreeze, desc: "unfreezes the time (doDaylightCycle)" do |handler, player, command, target, optparse|
        handler.acl_verify(player)
        $mcl.server.invoke "/gamerule doDaylightCycle true"
      end



      # ==========
      # = Macros =
      # ==========
      register_command :peace, desc: "sets up a friendly world" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/difficulty 0"
        $mcl.server.invoke "/gamerule doMobSpawning false"
        $mcl.server.invoke "/gamerule keepInventory true"
        $mcl.server.invoke "/gamerule naturalRegeneration true"
        sleep 1
        $mcl.server.invoke "/difficulty 1"
      end
      register_command :diehard, desc: "sets up a unfriendly world" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/difficulty 3"
        $mcl.server.invoke "/gamerule doMobSpawning true"
        $mcl.server.invoke "/gamerule naturalRegeneration true"
        $mcl.server.invoke "/gamerule keepInventory false"
      end
      register_command :hardcore, desc: "sets up a hardcore world" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/difficulty 3"
        $mcl.server.invoke "/gamerule doMobSpawning true"
        $mcl.server.invoke "/gamerule naturalRegeneration false"
        $mcl.server.invoke "/gamerule keepInventory false"
      end
    end

    def cow target, pos = "~ ~ ~"
      $mcl.server.invoke "/execute #{target} ~ ~ ~ summon Cow #{pos} {DropChances:[0F,0F,0F,0F,0F]}"
    end
  end
end
