module Mcl
  Mcl.reloadable(:HMMclBoot)
  class HMMclBoot < Handler
    def setup
      # server version
      register_parser(/Starting minecraft server version (.+)/i) do |res, r|
        $mcl.log.info "[CORE] Recognized minecraft server version `#{r[1]}'"
        $mcl_server_version = $mcl.server.version = r[1]
        $mcl.server.update_status :booting
      end

      # world
      register_parser(/Preparing level "([a-z0-9_\-\/]+)"/i) do |res, r|
        $mcl.log.info "[CORE] Recognized minecraft world `#{r[1]}'"
        $mcl_server_world = $mcl.server.world = r[1]
      end

      # boot time
      register_parser(/Done \(([\d\.,]+)s\)! For help, type "help"( or "\?")?/i) do |res, r|
        srvrdy = r[1].to_s.gsub(",", ".")
        $mcl.log.info "[CORE] Recognized SRVRDY after #{srvrdy}s on tick #{$mcl.eman.tick}"
        $mcl_server_boottime = $mcl.server.boottime = srvrdy.to_f
        $mcl.server.update_status :running

        app.handlers.each do |handler|
          app.devlog "[SETUP] Signaling SRVRDY to handler `#{handler.class.name}'", scope: "plugin_load"
          handler.srvrdy
        end
      end

      # EULA
      register_parser(/^You need to agree to the EULA in order to run the server/i) do |res, r|
        $mcl.log.info "[CORE] Recognized EULA halt on tick #{$mcl.eman.tick}, patching..."
        eula = File.read("#{$mcl.server.root}/eula.txt")
        File.open("#{$mcl.server.root}/eula.txt", "wb") {|f| f.write(eula.gsub("eula=false", "eula=true")) }
        $mcl.server.invoke("/stop") rescue Errno::EPIPE
      end

      # Portfail
      register_parser(/^\*\*\*\* FAILED TO BIND TO PORT!/i) do |res, r|
        $mcl.log.info "[CORE] Recognized stalled server (FAILED TO BIND TO PORT #{$mcl.server.port}) on tick #{$mcl.eman.tick}, rebooting..."
        $mcl.server.update_status :stalled
        $mcl_reboot = true
      end

      # shutdown
      register_parser(/\AStopping server\z/i) do |res, r|
        if res.thread == "server shutdown thread" && res.channel == "info"
          $mcl.log.info "[CORE] Recognized SRVSHT on tick #{$mcl.eman.tick}"
          $mcl.server.update_status :stopping
        end
      end

      # world saving
      register_parser(/^Saving the (?:key => "value", world|game)/i) { $world_saved = false }
      register_parser(/^Saved the (?:key => "value", world|game)/i) { $world_saved = true }
    end
  end
end
