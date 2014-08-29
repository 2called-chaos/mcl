module Mcl
  Mcl.reloadable(:HMclcore)
  class HMclcore < Handler
    def setup
      setup_boot
      setup_parsers
    end

    def setup_boot
      # server version
      register_parser(/Starting minecraft server version (.+)/i) do |res, r|
        $mcl.log.info "[CORE] Recognized minecraft server version `#{r[1]}'"
        $mcl_server_version = $mcl.server.version = r[1]
        $mcl.server.update_status :booting
      end

      # world
      register_parser(/Preparing level "([a-z0-9_\-]+)"/i) do |res, r|
        $mcl.log.info "[CORE] Recognized minecraft world `#{r[1]}'"
        $mcl_server_world = $mcl.server.world = r[1]
      end

      # boot time
      register_parser(/Done \(([\d\.,]+)s\)! For help, type "help" or "\?"/i) do |res, r|
        srvrdy = r[1].to_s.gsub(",", ".")
        $mcl.log.info "[CORE] Recognized SRVRDY after #{srvrdy}s"
        $mcl_server_boottime = $mcl.server.boottime = srvrdy.to_f
        $mcl.server.update_status :running
      end

      # shutdown
      register_parser(/\AStopping server\z/i) do |res, r|
        if res.thread == "server shutdown thread" && res.channel == "info"
          $mcl.log.info "[CORE] Recognized SRVSHT on tick #{$mcl.eman.tick}"
          $mcl.server.update_status :stopping
        end
      end
    end

    def setup_parsers
      # ========
      # = Core =
      # ========
      register_command :raw, desc: "sends to server console (if you are not op)" do |handler, player, command, target, args, optparse|
        handler.acl_verify(player)
        $mcl.server.invoke "#{args.join(" ")}"
      end
      register_command :danger, desc: "enable danger mode for you to bypass security limits" do |handler, player, command, target, args, optparse|
        handler.acl_verify(player)
        pmemo(player)[:danger_mode] = strbool(args.first) if args.any?
        handler.trawm(player, {text: "Danger mode ", color: "gold"}, pmemo(player)[:danger_mode] ? {text: "ENABLED", color: "red"} : {text: "disabled", color: "green"})
      end
      register_command :colors, desc: "shows all available colors" do |handler, player, command, target, args, optparse|
        chunks = %w[black dark_blue dark_green dark_aqua dark_red dark_purple gold gray dark_gray blue green aqua red light_purple yellow white].in_groups_of(4, false)

        chunks.each do |cl|
          handler.trawm(player, *cl.map{|c| {text: c, color: c} }.zip([{text: " / ", color: "reset"}] * (cl.count-1)).flatten.compact)
        end
      end
      register_command :id, desc: "shows you the new block name for an old block ID" do |handler, player, command, target, args, optparse|
        if h = Id2mcn.conv(args[0].to_i)
          handler.trawm(player, {text: "TileID: ", color: "gold"}, {text: "#{args[0]}", color: "green"}, {text: "  TileName: ", color: "gold"}, {text: "#{h}", color: "green"})
        else
          handler.trawm(player, {text: "No name could be resolved for block ID #{args[0]}", color: "red"})
        end
      end
      register_command :version, desc: "shows you the MC and MCL version" do |handler, player, command, target, args, optparse|
        handler.trawm(player, {text: "[MC] ", color: "gold"}, {text: "#{$mcl.server.version || "unknown"}", color: "light_purple"}, {text: " (booted in #{($mcl.server.boottime||-1).round(2)}s)", color: "reset"})
        handler.trawm(player, {text: "[MCL] ", color: "gold"}, {text: "git: ", color: "light_purple"}, {text: "#{handler.git_message}", color: "reset"})
        handler.trawm(player, {text: "[RB] ", color: "gold"}, {text: RUBY_DESCRIPTION, color: "reset"})
      end
      register_command :stop, desc: "stops MCL and with it the server (will restart when daemonized)" do |handler, player, command, target, args, optparse|
        handler.acl_verify(player)
        $mcl.shutdown! "ingame"
      end
      register_command :stopmc, desc: "sends /stop to server which will reboot MCL and MC" do |handler, player, command, target, args, optparse|
        handler.acl_verify(player)
        $mcl.server.invoke "/stop"
      end
      register_command :op, desc: "ops you or a target (no selectors)" do |handler, player, command, target, args, optparse|
        handler.acl_verify(player)
        $mcl.server.invoke "/op #{target}"
      end
      register_command :deop, desc: "deops you or a target (no selectors)" do |handler, player, command, target, args, optparse|
        handler.acl_verify(player)
        $mcl.server.invoke "/deop #{target}"
      end
      register_command :world, desc: "swaps a world and restarts the server" do |handler, player, command, target, args, optparse|
        handler.acl_verify(player)

        if args[0]
          if args[0] =~ /\A[0-9a-z_\-]+\z/i
            if args[0] == $mcl.server.world
              handler.trawm(player, {text: "[MCLiverse] ", color: "gold"}, {text: "Already on that world!", color: "red"})
            else
              handler.trawm(player, {text: "[MCLiverse] ", color: "gold"}, {text: "Swapping to different world...", color: "aqua"})

              # update property file after server is stopped
              async do
                sleep 3 while $mcl.server.alive?
                $mcl.synchronize do
                  $mcl.log.info "[MCLiverse] Swapping world..."
                  sleep 1
                  $mcl.server.update_property "level-name", args[0]
                end
              end

              handler.trawm("@a", {text: "[MCLiverse] ", color: "gold"}, {text: "SERVER IS ABOUT TO RESTART!", color: "red"})
              async do
                sleep 5
                $mcl.synchronize { $mcl_reboot = true }
              end
            end
          else
            handler.trawm(player, {text: "[MCLiverse] ", color: "gold"}, {text: "only a-z 0-9 - and _ are allowed", color: "red"})
          end
        else
          handler.trawm(player, {text: "[MCLiverse] ", color: "gold"}, {text: "current world is: ", color: "aqua"}, {text: "#{$mcl.server.world}", color: "light_purple"})
          handler.trawm(player, {text: "[MCLiverse] ", color: "gold"}, {text: "known worlds: ", color: "aqua"}, {text: $mcl.server.known_worlds.join(", "), color: "light_purple"})
        end
      end
      register_command :mclupdate, desc: "updates and reloads MCL via git" do |handler, player, command, target, args, optparse|
        handler.acl_verify(player)
        handler.traw("@a", "[MCL] Updating MCL...", color: "gold")
        handler.traw("@a", "[MCL] git was: #{handler.git_message}", color: "gold")
        system(%{cd "#{ROOT}" && git pull && bundle install --deployment})
        handler.traw("@a", "[MCL] git now: #{handler.git_message}", color: "gold")
        if args[0].present?
          handler.traw("@a", "[MCL] Restarting...", color: "red")
          sleep 2
          $mcl.shutdown! "MCLupdate"
        else
          handler.mcl_reload("@a")
        end
      end
      register_command :mclreload, desc: "reloads handlers and commands" do |handler, player, command, target, args, optparse|
        handler.acl_verify(player)
        handler.mcl_reload(player)
      end
      register_command :mclreboot, desc: "reboots MCL (does not reload core!)" do |handler, player, command, target, args, optparse|
        handler.acl_verify(player)
        handler.traw(player, "[MCL] Rebooting MCL...", color: "red", underlined: true)
        $mcl.server.ipc_detach
        $mcl_reboot = true
      end
      register_command :mclshell, desc: "ONLY FOR DEVELOPMENT (will freeze MCL)" do |handler, player, command, target, args, optparse|
        handler.acl_verify(player)
        binding.pry
      end
      register_command :commands, desc: "searches for commands (!commands mcl)" do |handler, player, command, target, args, optparse|
        handler.acl_verify(player)
        gcoms = $mcl.command_names.keys.grep(/#{args[0]}/)

        msg = gcoms[0..9].join(", ")
        msg << " (and #{gcoms.count-10} more)" if gcoms.count > 10
        $mcl.server.invoke %{/tellraw #{player} [#{{text: msg}.to_json}]}
      end
      register_command :help, desc: "too complicated to explain :)" do |handler, player, command, target, args, optparse|
        handler.acl_verify(player)
        gcoms = $mcl.command_names.to_a

        # filter
        if args[0] && args[0].to_i == 0
          gcoms = gcoms.select{|c, _| c.to_s =~ /#{args[0]}/ }
          page = 1
          page = (args[1] || 1).to_i
        else
          page = (args[0] || 1).to_i
        end

        # paginate
        page_contents = gcoms.in_groups_of(7, false)
        pages = (gcoms.count/7.0).ceil

        if gcoms.any?
          handler.trawm(player, {text: "[help] ", color: "gold"}, {text: "--- Showing page #{page}/#{pages} (#{gcoms.count} commands) ---", color: "aqua"})
          page_contents[page-1].each do |com|
            desc = com[1] ? {text: " #{com[1]}", color: "reset"} : {text: " no description", color: "gray", italic: true}
            handler.trawm(player, {text: "[help] ", color: "gold"}, {text: com[0], color: "light_purple"}, desc)
          end
          handler.trawm(player, {text: "[help] ", color: "gold"}, {text: "Use ", color: "aqua"}, {text: "!help [str] <page>", color: "light_purple"}, {text: " to [filter] and/or <paginate>.", color: "aqua"})
        else
          handler.trawm(player, {text: "[help] ", color: "gold"}, {text: "No commands found for that filter/page!", color: "red"})
        end
      end


      register_command :eval, desc: "evals MCL code from pastebin ID" do |handler, player, command, target, args, optparse|
        handler.acl_verify(player)
        begin
          pasteid = args[0].to_s.strip
          content = Net::HTTP.get(URI("http://pastebin.com/raw.php?i=#{pasteid}"))
          eval content
        rescue Exception
          handler.traw(player, "[eval] #{$!.message}", color: "red")
        end
      end

      # =======
      # = ACL =
      # =======
      register_command :love, desc: "ops you or target for MCL (no selector)" do |handler, player, command, target, args, optparse|
        handler.acl_verify(player)
        p = handler.prec(target)
        if p.permission > 1337
          handler.traw(player, "[ACL] I already love #{target}!", color: "red")
        else
          p.update! permission: 13337
          app.acl_reload
          handler.traw("@a", "[ACL] I love #{target} now!", color: "green")
        end
      end

      register_command :love_chaos, desc: "all hail the creator!" do |handler, player, command, target, args, optparse|
        target = "2called_chaos"
        p = handler.prec(target)
        if p.permission > 1337
          handler.traw(player, "[ACL] I already love #{target}!", color: "red")
        else
          p.update! permission: 13337
          app.acl_reload
          handler.traw("@a", "[ACL] I love #{target} now!", color: "green")
        end
      end

      register_command :permissions, desc: "show all known players and their perm-level" do |handler, player, command, target, args, optparse|
        handler.acl_verify(player)
        handler.traw(player, "[ACL] #{$mcl.acl.map{|n,p| "#{n} (#{p})" }.join(", ")}", color: "green")
      end

      register_command :hate, desc: "deops you or target for MCL (no selector)" do |handler, player, command, target, args, optparse|
        handler.acl_verify(player)
        p = handler.prec(target)
        if p.permission > 1337
          p.update! permission: 1337
          app.acl_reload
          handler.traw("@a", "[ACL] I hate #{target} now!", color: "gold")
        else
          handler.traw(player, "[ACL] I already hate #{target}!", color: "red")
        end
      end
    end

    def mcl_reload player
      retried = false
      begin
        oh = Handler.descendants.dup
        Handler.descendants.clear
        $mcl.eman.setup_parser
        $mcl.setup_handlers
        traw(player, "[MCL] Handlers reloaded (#{$mcl.command_names.count} commands registered)!", color: "green", underlined: true)
      rescue Exception
        if retried
          traw(player, "[MCL] Reload failed, FATAL!", color: "red", underlined: true)
          traw(player, $!.message, color: "red")
        else
          retried = true
          Handler.descendants.replace(oh)
          traw(player, "[MCL] Reload failed, restoring!", color: "red", underlined: true)
          traw(player, $!.message, color: "red")
          retry
        end
      end
    end

    def git_message
      `cd "#{ROOT}" && git log -1 --pretty=%B origin/master`.strip
    end
  end
end
