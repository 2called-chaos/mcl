module Mcl
  class Server
    module Helper
      def msg player, msg
        invoke("/msg #{player} #{msg}")
      end

      def gm mode, target
        invoke %{/gamemode #{mode} #{target}}
      end

      def traw player, msg = "", opts = {}
        trawm player, {text: msg}.merge(opts)
      end

      def trawm player, *msgs
        r = msgs.map do |msg|
          msg.is_a?(Hash) ? msg : {text: msg}
        end
        invoke %{/tellraw #{player} [#{r.map(&:to_json).join(",")}]}
      end
    end
  end
end

