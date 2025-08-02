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
        invoke %{/tellraw #{player} ["", #{r.map(&:to_json).join(",")}]}
      end

      def trawt player, tit, *msgs
        r = [{text: "[#{tit}] ", color: "light_purple"}]
        msgs.each do |msg|
          r << (msg.is_a?(Hash) ? msg : {text: msg})
        end
        invoke %{/tellraw #{player} ["", #{r.map(&:to_json).join(",")}]}
      end

      def human_bytes bytes
        return false unless bytes
        {
          'B'  => 1024,
          'KB' => 1024 * 1024,
          'MB' => 1024 * 1024 * 1024,
          'GB' => 1024 * 1024 * 1024 * 1024,
          'TB' => 1024 * 1024 * 1024 * 1024 * 1024
        }.each_pair { |e, s| return "#{(bytes.to_f / (s / 1024)).round(2)} #{e}" if bytes < s }
      end

      def uniqid prefix = ''
        t = Time.now.to_f
        sprintf("%s%8x%05x", prefix, t.floor, (t - t.floor) * 1000000)
      end
    end
  end
end
