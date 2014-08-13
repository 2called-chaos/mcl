module Mcl
  Mcl.reloadable(:HMclcore)
  class HMclcore < Handler
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
          pasteid = command.split(" ")[1].to_s.strip
          content = Net::HTTP.get(URI("http://pastebin.com/raw.php?i=#{pasteid}"))
          eval content
        rescue Exception
          handler.traw(player, "[eval] #{$!.message}", color: "red")
        end
      end
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
