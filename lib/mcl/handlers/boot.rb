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
      register_parser(/Done \(([\d\.,]+)s\)! For help, type "help" or "\?"/i) do |res, r|
        srvrdy = r[1].to_s.gsub(",", ".")
        $mcl.log.info "[CORE] Recognized SRVRDY after #{srvrdy}s on tick #{$mcl.eman.tick}"
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
  end
end
