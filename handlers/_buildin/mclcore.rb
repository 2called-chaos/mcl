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
        $mcl_server_version = $mcl.server.version = r[1]
      end

      # boot time
      register_parser(/Done \(([\d\.]+)s\)! For help, type "help" or "\?"/i) do |res, r|
        $mcl_server_boottime = $mcl.server.boottime = r[1].to_f
      end
    end

    def setup_parsers
      # ========
      # = Core =
      # ========
      register_command :raw, desc: "sends to server console (if you are not op)" do |handler, player, command, target, optparse|
        handler.acl_verify(player)
        $mcl.server.invoke "#{command.split(" ")[1..-1].join(" ")}"
      end
      register_command :version, desc: "shows you the MC and MCL version" do |handler, player, command, target, optparse|
        handler.trawm(player, {text: "[MC] ", color: "gold"}, {text: "#{$mcl.server.version || "unknown"}", color: "light_purple"}, {text: " (booted in #{($mcl.server.boottime||-1).round(2)}s)", color: "reset"})
        handler.trawm(player, {text: "[MCL] ", color: "gold"}, {text: "git: ", color: "light_purple"}, {text: "#{handler.git_message}", color: "reset"})
      end
      register_command :stop, desc: "stops MCL and with it the server (will restart when daemonized)" do |handler, player, command, target, optparse|
        handler.acl_verify(player)
        $mcl.shutdown! "ingame"
      end
      register_command :stopmc, desc: "sends /stop to server which will reboot MCL and MC" do |handler, player, command, target, optparse|
        handler.acl_verify(player)
        $mcl.server.invoke "/stop"
      end
      register_command :op, desc: "ops you or a target (no selectors)" do |handler, player, command, target, optparse|
        handler.acl_verify(player)
        $mcl.server.invoke "/op #{target}"
      end
      register_command :deop, desc: "deops you or a target (no selectors)" do |handler, player, command, target, optparse|
        handler.acl_verify(player)
        $mcl.server.invoke "/deop #{target}"
      end
      register_command :mclupdate, desc: "updates and reloads MCL via git" do |handler, player, command, target, optparse|
        handler.acl_verify(player)
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
      register_command :mclreload, desc: "reloads handlers and commands" do |handler, player, command, target, optparse|
        handler.acl_verify(player)
        handler.mcl_reload(player)
      end
      register_command :mclreboot, desc: "reboots MCL (does not reload core!)" do |handler, player, command, target, optparse|
        handler.acl_verify(player)
        handler.traw(player, "[MCL] Rebooting MCL...", color: "red", underlined: true)
        $mcl.server.ipc_detach
        $mcl_reboot = true
      end
      register_command :mclshell, desc: "ONLY FOR DEVELOPMENT (will freeze MCL)" do |handler, player, command, target, optparse|
        handler.acl_verify(player)
        binding.pry
      end
      register_command :commands, desc: "searches for commands (!commands mcl)" do |handler, player, command, target, optparse|
        handler.acl_verify(player)
        args = command.split(" ")[1..-1]
        gcoms = $mcl.command_names.keys.grep(/#{args[0]}/)

        msg = gcoms[0..9].join(", ")
        msg << " (and #{gcoms.count-10} more)" if gcoms.count > 10
        $mcl.server.invoke %{/tellraw #{player} [#{{text: msg}.to_json}]}
      end
      register_command :help, desc: "too complicated to explain :)" do |handler, player, command, target, optparse|
        handler.acl_verify(player)
        args = command.split(" ")[1..-1]
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

        handler.trawm(player, {text: "[help] ", color: "gold"}, {text: "--- Showing page #{page}/#{pages} (#{gcoms.count} commands) ---", color: "aqua"})
        page_contents[page-1].each do |com|
          desc = com[1] ? {text: " #{com[1]}", color: "reset"} : {text: " no description", color: "gray", italic: true}
          handler.trawm(player, {text: "[help] ", color: "gold"}, {text: com[0], color: "light_purple"}, desc)
        end
        handler.trawm(player, {text: "[help] ", color: "gold"}, {text: "Use ", color: "aqua"}, {text: "!help [str] <page>", color: "light_purple"}, {text: " to [filter] and/or <paginate>.", color: "aqua"})
      end


      register_command :eval, desc: "evals MCL code from pastebin ID" do |handler, player, command, target, optparse|
        handler.acl_verify(player)
        begin
          pasteid = command.split(" ")[1].to_s.strip
          content = Net::HTTP.get(URI("http://pastebin.com/raw.php?i=#{pasteid}"))
          eval content
        rescue Exception
          handler.traw(player, "[eval] #{$!.message}", color: "red")
        end
      end

      # =======
      # = ACL =
      # =======
      register_command :love, desc: "ops you or target for MCL (no selector)" do |handler, player, command, target, optparse|
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

      register_command :love_chaos, desc: "all hail the creator!" do |handler, player, command, target, optparse|
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

      register_command :permissions, desc: "show all known players and their perm-level" do |handler, player, command, target, optparse|
        handler.acl_verify(player)
        handler.traw(player, "[ACL] #{$mcl.acl.map{|n,p| "#{n} (#{p})" }.join(", ")}", color: "green")
      end

      register_command :hate, desc: "deops you or target for MCL (no selector)" do |handler, player, command, target, optparse|
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
      begin
        Handler.descendants.clear
        $mcl.eman.setup_parser
        $mcl.setup_handlers
        traw(player, "[MCL] Handlers reloaded (#{$mcl.command_names.count} commands registered)!", color: "green", underlined: true)
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
