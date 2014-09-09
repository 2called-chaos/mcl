module Mcl
  Mcl.reloadable(:HMMclCore)
  class HMMclCore < Handler
    def setup
      register_danger(:admin)
      register_help(:guest)
      register_mclreboot(:admin)
      register_mclreload(:admin)
      register_mclshell(:root)
      register_mclupdate(:root)
      register_raw(:admin)
      register_stop(:admin)
      register_stopmc(:root)
      register_version(:member)
    end

    def register_danger acl_level
      register_command :danger, desc: "enable danger mode for you to bypass security limits", acl: acl_level do |player, args|
        pmemo(player)[:danger_mode] = strbool(args.first) if args.any?
        trawm(player, {text: "Danger mode ", color: "gold"}, pmemo(player)[:danger_mode] ? {text: "ENABLED", color: "red"} : {text: "disabled", color: "green"})
      end
    end

    def register_help acl_level
      register_command :help, desc: "too complicated to explain :)", acl: acl_level do |player, args|
        gcoms = $mcl.command_names.to_a

        # filter by permission
        gcoms = gcoms.select {|com| ($mcl.pman.acl[player] || 0) >= $mcl.command_acls[com[0]] }

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
          trawm(player, title("help", "gold"), {text: "--- Showing page #{page}/#{pages} (#{gcoms.count} commands) ---", color: "aqua"})
          page_contents[page-1].each do |com|
            desc = com[1] ? {text: " #{com[1]}", color: "reset"} : {text: " no description", color: "gray", italic: true}
            trawm(player, title("help", "gold"), {text: com[0], color: "light_purple"}, desc)
          end
          trawm(player, title("help", "gold"), {text: "Use ", color: "aqua"}, {text: "!help [str] <page>", color: "light_purple"}, {text: " to [filter] and/or <paginate>.", color: "aqua"})
        else
          trawm(player, title("help", "gold"), {text: "No commands found for that filter/page!", color: "red"})
        end
      end
    end

    def register_mclreboot acl_level
      register_command :mclreboot, desc: "reboots MCL (does not reload core!)", acl: acl_level do |player|
        traw(player, "[MCL] Rebooting MCL...", color: "red", underlined: true)
        $mcl.server.ipc_detach
        $mcl_reboot = true
      end
    end

    def register_mclreload acl_level
      register_command(:mclreload, desc: "reloads handlers and commands", acl: acl_level) {|player| mcl_reload(player) }
    end

    def register_mclshell acl_level
      register_command(:mclshell, desc: "ONLY FOR DEVELOPMENT (will freeze MCL)", acl: acl_level) { binding.pry }
    end

    def register_mclupdate acl_level
      register_command :mclupdate, desc: "updates and reloads MCL via git", acl: acl_level do |player, args|
        traw("@a", "[MCL] Updating MCL...", color: "gold")
        traw("@a", "[MCL] git was: #{git_message}", color: "gold")
        system(%{cd "#{ROOT}" && git pull && bundle install --deployment})
        traw("@a", "[MCL] git now: #{git_message}", color: "gold")
        if args[0].present?
          traw("@a", "[MCL] Restarting...", color: "red")
          sleep 2
          $mcl.shutdown! "MCLupdate"
        else
          mcl_reload("@a")
        end
      end
    end

    def register_raw acl_level
      register_command :raw, desc: "sends to server console (if you are not op)", acl: acl_level do |player, args|
        $mcl.server.invoke "#{args.join(" ")}"
      end
    end

    def register_stop acl_level
      register_command(:stop, desc: "stops MCL and with it the server (will restart when daemonized)", acl: acl_level) { $mcl.shutdown! "ingame" }
    end

    def register_stopmc acl_level
      register_command(:stopmc, desc: "sends /stop to server which will reboot MCL and MC", acl: acl_level) { $mcl.server.invoke "/stop" }
    end

    def register_version acl_level
      register_command :version, desc: "shows you the MC and MCL version", acl: acl_level do |player, args|
        trawm(player, title("MC", "gold"), {text: "#{$mcl.server.version || "unknown"}", color: "light_purple"}, {text: " (booted in #{($mcl.server.boottime||-1).round(2)}s)", color: "reset"})
        trawm(player, title("MCL", "gold"), {text: "git: ", color: "light_purple"}, {text: "#{git_message}", color: "reset"})
        trawm(player, title("RB", "gold"), {text: RUBY_DESCRIPTION, color: "reset"})
      end
    end

    module Helper
      def git_message
        `cd "#{ROOT}" && git log -1 --pretty=%B origin/master`.strip
      end

      def mcl_reload player
        retried = false
        oh = Handler.descendants.dup
        Handler.descendants.clear
        $mcl.eman.setup_parser
        begin
          $mcl.setup_handlers(!retried)
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
    end
    include Helper
  end
end
