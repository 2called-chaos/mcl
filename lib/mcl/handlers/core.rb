module Mcl
  Mcl.reloadable(:HMMclCore)
  class HMMclCore < Handler
    def setup
      early_console_server_shutdown
      register_sprop(:root)
      register_danger(:admin)
      register_help(:guest)
      register_mclreboot(:admin)
      register_mclreload(:admin)
      register_mclreloadcfg(:root)
      register_mclshell(:root)
      register_mclupdate(:root)
      register_raw(:admin)
      register_stop(:admin)
      register_stopmc(:root)     # <---- root permissions because it will stall the server due to bug MC-63802
      register_version(:member)
    end

    def early_console_server_shutdown
      app.ipc_early do
        app.log.debug "[SHUTDOWN] Stopping console socket server..."
        app.console_server.shutdown!
      end
    end

    def register_danger acl_level
      register_command :danger, desc: "enable danger mode for you to bypass security limits", acl: acl_level do |player, args|
        pmemo(player)[:danger_mode] = strbool(args.first) if args.any?
        trawm(player, {text: "Danger mode ", color: "gold"}, pmemo(player)[:danger_mode] ? {text: "ENABLED", color: "red"} : {text: "disabled", color: "green"})
      end
    end

    def register_sprop acl_level
      register_command :sprop, desc: "read/change server properties (more info with !sprop)", acl: acl_level do |player, args|
        case args.count
        when 0 # usage
          trawt(player, "SPROP", {text: "Usage: ", color: "gold"}, {text: "!sprop book", color: "aqua"})
          trawt(player, "SPROP", {text: "Usage: ", color: "gold"}, {text: "!sprop <property> [value] [force]", color: "aqua"})
        when 1 # read / book
          if args.first == "book"
            book_data = [].tap do |b|
              x, bs = 0, []
              $mcl.server.properties.each_with_index do |(k, v), i|
                next if v == :comment
                x += k.to_s.length > 20 ? 2 : 1

                val = v.blank? ? %Q{"-blank-", color: "gray", italic: true} : %Q{"#{v}"}
                bs << %Q{{text: "#{k}\\n", color: "#{i % 2 == 0 ? :blue : :dark_blue}", hoverEvent:{action:"show_text",value:#{val}},clickEvent:{action:"run_command", value:"!sprop #{k}"}}}
                if x >= 13
                  b << bs.join("\n")
                  x, bs = 0, []
                end
              end
              b << bs.join("\n")
            end
            $mcl.server.invoke book(player, "Server properties", book_data)
          else
            if $mcl.server.properties.key?(args.first)
              sval = $mcl.server.properties[args.first]
              val = sval.blank? ? {text: "-blank-", color: "gray", italic: true} : {text: "#{sval}", color: "aqua"}
              trawt(player, "SPROP", {text: "Value of property ", color: "gold"}, {text: "#{args.first}", color: "dark_aqua"}, {text: " is ", color: "gold"}, val)
            else
              trawt(player, "SPROP", {text: "Property ", color: "red"}, {text: "#{args.first}", color: "dark_aqua"}, {text: " does not exist.", color: "red"})
            end
          end
        else # update
          prop = args.shift
          force = args.pop if args.last == "force"
          val = args.join(" ")
          pwas = $mcl.server.properties[prop]

          if !pwas && !force
            trawt(player, "SPROP", {text: "Property ", color: "red"}, {text: "#{prop}", color: "dark_aqua"}, {text: " does not exist.", color: "red"})
            trawt(player, "SPROP", {text: "If you want to add this property use force!", color: "red"})
          else
            $mcl.server.update_property(prop, val)
            if pwas
              trawt(player, "SPROP",
                {text: "Set property ", color: "gold"},
                {text: "#{prop}", color: "dark_aqua"}, {text: " to ", color: "gold"}, {text: "#{val}", color: "aqua"},
                {text: " (was ", color: "gold"}, {text: "#{pwas}", color: "aqua"}, {text: ")", color: "gold"}
              )
            else
              trawt(player, "SPROP", {text: "Added new property ", color: "gold"}, {text: "#{prop}", color: "dark_aqua"}, {text: " with value ", color: "gold"}, {text: "#{val}", color: "aqua"} )
            end
            trawt(player, "SPROP", {text: "Changes require a server restart to take effect!", color: "yellow"})
          end
        end
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
      register_command :mclreboot, desc: "reboots MCL (does not reload core!)", acl: acl_level do |player, args|
        traw(player, "[MCL] Rebooting MCL...", color: "red", underlined: true)
        if (args.empty? || strbool(args.first))
          $mcl.server.ipc_detach
        else
          announce_server_restart
          sleep 3
        end
        $mcl_reboot = true
      end
    end

    def register_mclreload acl_level
      register_command(:mclreload, desc: "reloads handlers and commands", acl: acl_level) {|player| mcl_reload(player) }
    end

    def register_mclreloadcfg acl_level
      register_command(:mclreloadcfg, desc: "reloads instance's yml config", acl: acl_level) do |player|
        begin
          $mcl.reload_config
          traw("@a", "[MCL] CFG reloaded!", color: "green")
        rescue
          traw("@a", "[MCL] #{$!.message}", color: "red")
        end
      end
    end

    def register_mclshell acl_level
      register_command(:mclshell, desc: "ONLY FOR DEVELOPMENT (will freeze MCL)", acl: acl_level) { binding.pry }
    end

    def register_mclupdate acl_level
      register_command :mclupdate, desc: "updates and reloads MCL via git", acl: acl_level do |player, args|
        traw("@a", "[MCL] Updating MCL...", color: "gold")
        traw("@a", "[MCL] git was: #{git_message}", color: "gold")
        if system(%{cd "#{ROOT}" && git pull && bundle install --deployment})
          traw("@a", "[MCL] git now: #{git_message}", color: "gold")
          if args[0].present?
            announce_server_restart
            traw("@a", "[MCL] Restarting...", color: "red")
            sleep 3
            $mcl.shutdown! "MCLupdate"
          else
            mcl_reload("@a")
          end
        else
          traw("@a", "[MCL] Update failed (manual update required)...", color: "red")
        end
      end
    end

    def register_raw acl_level
      register_command :raw, desc: "sends to server console (if you are not op)", acl: acl_level do |player, args|
        $mcl.server.invoke "#{args.join(" ")}"
      end
    end

    def register_stop acl_level
      register_command(:stop, desc: "stops MCL and with it the server (will restart when daemonized)", acl: acl_level) do
        announce_server_restart
        sleep 3
        $mcl.shutdown! "ingame"
      end
    end

    def register_stopmc acl_level
      register_command(:stopmc, desc: "sends /stop to server which will reboot MCL and MC", acl: acl_level) do
        announce_server_restart
        sleep 3
        $mcl.server.invoke "/stop"
      end
    end

    def register_version acl_level
      register_command :version, desc: "shows you the MC and MCL version", acl: acl_level do |player, args|
        trawm(player, title("MC", "gold"), {text: "#{$mcl.server.version || "unknown"}", color: "light_purple"}, {text: " (booted in #{($mcl.server.boottime||-1).round(2)}s)", color: "reset"})
        trawm(player, title("MCL", "gold"), {text: "git: ", color: "light_purple"}, {text: "#{$mcl.booted_mcl_rev}", color: "reset"})
        trawm(player, title("RB", "gold"), {text: RUBY_DESCRIPTION, color: "reset"})
      end
    end

    module Helper
      def git_message
        Mcl.git_message
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
