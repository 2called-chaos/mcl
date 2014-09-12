module Mcl
  class Handler
    module Helper
      def detect_player_position p, opts = {}, &block
        opts = opts.reverse_merge(pos: "~ ~1 ~", block: "minecraft:air")
        $mcl.server.invoke %{/execute #{p} ~ ~ ~ testforblock #{opts[:pos]} #{opts[:block]}}
        promise do |pr|
          pr.condition { pmemo(p)[:detected_pos] }
          pr.callback { block.call(pmemo(p).delete(:detected_pos)) }
        end
      end

      def indicate_coord p, coord, type = nil
        coord = coord.join(" ") if coord.respond_to?(:each)
        parts = coord.split(" ").map(&:to_f)
        case type.to_s.strip
          when "p", "particle" then $mcl.server.invoke "/particle reddust #{coord} 0 0 0 1 100 force"
          when "b", "barrier" then $mcl.server.invoke "/particle barrier #{coord} 0 0 0 1 1 force"
          when "crystal" then $mcl.server.invoke "/summon EnderCrystal #{parts[0]} #{parts[1] - 0.5} #{parts[2]}"
          when "c", "cross"
            $mcl.server.invoke "/particle reddust #{coord} 1 0 0 1 100 force"
            $mcl.server.invoke "/particle reddust #{coord} 0 1 0 1 100 force"
            $mcl.server.invoke "/particle reddust #{coord} 0 0 1 1 100 force"
          else $mcl.server.invoke "/particle largeexplode #{coord} 0 0 0 1 10 force"
        end
      end

      def require_danger_mode p, text = "Danger mode required!"
        if pmemo(p)[:danger_mode]
          return false
        else
          trawm(p, {text: text, color: "red"}, {text: " (enable with '!danger on/off')", color: "yellow"})
          return true
        end
      end

      def announce_server_restart
        $mcl.server.invoke %{/title @a times 10 120 60}
        $mcl.server.invoke %{/title @a subtitle [{text:"a", color: "green", obfuscated: true},{text:" get ready for immediate reboot ", color: "gold", obfuscated: false},{text:"a", color: "green", obfuscated: true}]}
        $mcl.server.invoke %{/title @a title {text:"Server is about to restart", color: "red"}}
      end

      def require_dm_for_selection p, p1, p2
        !pmemo(p)[:danger_mode] && coord_dimensions(p1, p2).inject(:*) > 100_000 && require_danger_mode(p, "Selections >100k blocks require danger mode to be enabled!")
      end

      def title t, color = "light_purple"
        { text: "[#{t}] ", color: color }
      end
    end
  end
end
