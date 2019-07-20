module Mcl
  class Handler
    module Helper
      def detect_player_position p, opts = {}, &block
        opts = opts.reverse_merge(pos: "~ ~1 ~", block: "minecraft:air")
        pmemo(p).delete(:detected_pos)

        $mcl.server.invoke do |v|
          v.default %{/execute #{p} ~ ~ ~ testforblock #{opts[:pos]} #{opts[:block]}}
          v.since "1.13", "17w45a", %{/execute as #{p} at #{p} run tp #{p} ~ ~ ~}

          promise do |pr|
            pr.condition { pmemo(p)[:detected_pos] }
            pr.callback { block.call(pmemo(p).delete(:detected_pos)) }
          end
        end
      end

      def indicate_coord p, coord, type = nil
        coord = coord.join(" ") if coord.respond_to?(:each)
        parts = coord.split(" ").map(&:to_f)
        case type.to_s.strip
          when "p", "particle" then $mcl.server.invoke "/particle reddust #{coord} 0 0 0 1 100 force"
          when "b", "barrier"
            $mcl.server.invoke do |v|
              v.default %{/particle barrier #{coord} 0 0 0 1 1 force}
              v.since "1.14", "18w43a", %{/particle barrier #{parts[0].to_i} #{parts[1] + 0.5} #{parts[2].to_i} 0 0 0 1 1 force}
            end
          when "crystal" then $mcl.server.invoke "/summon ender_crystal #{parts[0] - 0.5} #{parts[1] - 0.5} #{parts[2] + 0.5}"
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
        $mcl.server.invoke %{/title @a subtitle [{"text":"a", "color": "green", "obfuscated": true},{"text":" get ready for immediate reboot ", "color": "gold", "obfuscated": false},{"text":"a", "color": "green", "obfuscated": true}]}
        $mcl.server.invoke %{/title @a title {"text":"Server is about to restart", "color": "red"}}
      end

      def require_dm_for_selection p, p1, p2
        !pmemo(p)[:danger_mode] && coord_dimensions(p1, p2).inject(:*) > 100_000 && require_danger_mode(p, "Selections >100k blocks require danger mode to be enabled!")
      end

      def title t, color = "light_purple"
        { text: "[#{t}] ", color: color }
      end

      def mc_numeric_version ver = nil
        ver ||= server.version
        ver.each_byte.with_index.inject(0) {|n, (c, i)| n + (255**(ver.length - i) * c) }
      end

      def mc_snapshot? ver = nil
        ver ||= server.version
        !!!Gem::Version.new(ver) rescue true
      end

      def mc_comparable_version ver
        Gem::Version.new(ver) rescue mc_numeric_version(ver)
      end

      def version_switch &block
        Server::VersionedSwitch.new(app, &block).compile($mcl.server.version)
      end

      def json_text *txt
        res = [].tap do |r|
          txt.each do |t|
            if t.is_a?(String)
              r << {text: t}
            else
              r << t
            end
          end
        end
        "[#{res.map(&:to_json).join(",")}]"
      end

      def json_etext *txt
        json_text(*txt).gsub('"', '\"')
      end

      def mc_version_compare v1, v2, meth = :==
        rv1 = mc_comparable_version(v1)
        rv2 = mc_comparable_version(v2)

        if rv1.class == rv2.class
          rv1.send(meth, rv2)
        elsif meth == :==
          false
        else
          raise ArgumentError, "uncomparable versions: #{v1} (#{v1.class}) ?=? #{v2} (#{v2.class})"
        end
      end

      def coord_save_optparse! opt, args
        argp = args.map {|arg| arg.is_a?(String) && arg.match(/\A\-[0-9]+\z/) ? arg.gsub("-", "#%#") : arg }
        opt.parse!(argp)
        argp.map {|arg| arg.is_a?(String) && arg.match(/\A#%#[0-9]+\z/) ? arg.gsub("#%#", "-") : arg }
      end
    end
  end
end
