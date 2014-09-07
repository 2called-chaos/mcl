module Mcl
  Mcl.reloadable(:HMclEval)
  class HMclEval < Handler
    def setup
      register_whois
    end

    def nsa_report target
      [
        %Q{{text: "Moep #{target}", color: "gold"}}
      ]
    end

    def register_eval
      register_command :whois, desc: "shows you exclusive NSA data about a player", acl: :mod do |player, args|
        handler.acl_verify(player)
        $mcl.server.invoke handler.book(player, "Report for #{target}", handler.nsa_report(target), author: "NSA")
      end
    end
  end
end
