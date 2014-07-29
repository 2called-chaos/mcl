module Mcl
  Mcl.reloadable(:HAliases)
  class HAliases < Handler
    def setup
      setup_parsers
    end

    def setup_parsers
      # ========
      # = Core =
      # ========
      register_command "raw" do |handler, player, command, target, optparse|
        $mcl.server.invoke "#{command.split(" ")[1..-1].join(" ")}"
      end
      register_command "stop" do |handler, player, command, target, optparse|
        $mcl.shutdown! "ingame"
      end
      register_command "stopmc" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/stop"
      end
      register_command "op" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/op #{target}"
      end
      register_command "deop" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/deop #{target}"
      end
      register_command "mclupdate" do |handler, player, command, target, optparse|
        handler.traw("@a", "[MCL] Updating MCL...", color: "gold")
        handler.traw("@a", "[MCL] git was: #{handler.git_message}", color: "gold")
        system(%{cd "#{ROOT}" && git pull && bundle install --deployment})
        handler.traw("@a", "[MCL] git now: #{handler.git_message}", color: "gold")
        if command.split(" ")[1].present?
          handler.traw("@a", "[MCL] Restarting...", color: "red")
          sleep 2
          $mcl.shutdown! "MCLupdate"
        else
          handler.mcl_reload("@a")
        end
      end
      register_command "mclreload"  do |handler, player, command, target, optparse|
        handler.mcl_reload(player)
      end
      register_command "mclreboot"  do |handler, player, command, target, optparse|
        handler.traw(player, "[MCL] Rebooting MCL...", color: "red", underlined: true)
        $mcl.server.ipc_detach
        $mcl_reboot = true
      end
      register_command "mclshell"  do |handler, player, command, target, optparse|
        binding.pry
      end


      register_command "eval"  do |handler, player, command, target, optparse|
        begin
          pasteid = c.split(" ")[1].to_s.strip
          content = Net::HTTP.get(URI("http://pastie.org/pastes/#{pasteid}/text"))
          eval content
        rescue Exception
          traw(player, "[eval] #{$!.message}", color: "red")
        end
      end

      # @todo list of generator urls => !generators


      # ==========
      # = Cheats =
      # ==========
      register_command "iamop" do |handler, player, command, target, optparse|
        $mcl.server.msg target, "dude, #{command} hasn't been implemented yet"
      end
      register_command "iamlegend" do |handler, player, command, target, optparse|
        $mcl.server.msg target, "dude, #{command} hasn't been implemented yet"
      end
      register_command "strike" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/execute #{target} ~ ~ ~ summon LightningBolt"
      end
      register_command "boat" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/execute #{target} ~ ~ ~ summon Boat ~ ~2 ~"
      end
      register_command "longwaydown" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/execute #{target} ~ ~ ~ tp @p ~ 1337 ~"
      end
      register_command "muuhhh" do |handler, player, command, target, optparse|
        handler.cow(target, "~ ~50 ~")
        sleep 3

        handler.cow(target, "~ ~50 ~")
        sleep 0.2
        handler.cow(target, "~ ~50 ~")
        sleep 3


        handler.cow(target, "~ ~50 ~")
        sleep 0.2
        handler.cow(target, "~ ~50 ~")
        sleep 0.2
        handler.cow(target, "~ ~50 ~")
        sleep 3

        100.times do
          handler.cow(target, "~ ~50 ~")
          sleep 0.05
        end
      end



      # ======
      # = XP =
      # ======
      register_command "l0" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/xp -10000L #{target}"
      end
      register_command "l30" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/xp 30L #{target}"
      end
      register_command "l1337" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/xp -10000L #{target}"
        $mcl.server.invoke "/xp 1337L #{target}"
      end



      # ===========
      # = Weather =
      # ===========
      register_command "sun" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/weather clear"
      end
      register_command "rain" do |handler, player, command, target, optparse|
        duration = command.split(" ")[1].presence
        $mcl.server.invoke "/weather rain #{duration}"
      end
      register_command "thunder" do |handler, player, command, target, optparse|
        duration = command.split(" ")[1].presence
        $mcl.server.invoke "/weather thunder #{duration}"
      end



      # ========
      # = Time =
      # ========
      register_command "morning" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/time set 0"
      end
      register_command "day" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/time set 6000"
      end
      register_command "noon" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/time set 6000"
      end
      register_command "evening" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/time set 12000"
      end
      register_command "night" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/time set 14000"
      end
      register_command "midnight" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/time set 18000"
      end
      register_command "freeze" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/gamerule doDaylightCycle false"
      end
      register_command "unfreeze" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/gamerule doDaylightCycle true"
      end



      # ==========
      # = Macros =
      # ==========
      register_command "peace" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/difficulty 0"
        $mcl.server.invoke "/gamerule doMobSpawning false"
        $mcl.server.invoke "/gamerule keepInventory true"
        $mcl.server.invoke "/gamerule naturalRegeneration true"
        sleep 1
        $mcl.server.invoke "/difficulty 1"
      end
      register_command "diehard" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/difficulty 3"
        $mcl.server.invoke "/gamerule doMobSpawning true"
        $mcl.server.invoke "/gamerule naturalRegeneration true"
        $mcl.server.invoke "/gamerule keepInventory false"
      end
      register_command "hardcore" do |handler, player, command, target, optparse|
        $mcl.server.invoke "/difficulty 3"
        $mcl.server.invoke "/gamerule doMobSpawning true"
        $mcl.server.invoke "/gamerule naturalRegeneration false"
        $mcl.server.invoke "/gamerule keepInventory false"
      end
    end

    def cow target, pos = "~ ~ ~"
      $mcl.server.invoke "/execute #{target} ~ ~ ~ summon Cow #{pos} {DropChances:[0F,0F,0F,0F,0F]}"
    end

    def mcl_reload player
      begin
        Handler.descendants.clear
        $mcl.eman.setup_parser
        $mcl.setup_handlers
        traw(player, "[MCL] Handlers reloaded!", color: "green", underlined: true)
      rescue Exception
        traw(player, "[MCL] Reload failed, rebooting!", color: "red", underlined: true)
        $mcl.server.ipc_detach
        $mcl_reboot = true
      end
    end

    def git_message
      `cd "#{ROOT}" && git log -1 --pretty=%B origin/master`.strip
    end
  end
end
