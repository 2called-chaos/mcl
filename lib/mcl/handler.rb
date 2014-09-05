module Mcl
  class Handler
    include API
    include BookVerter
    include Geometry
    include Shortcuts

    attr_reader :app


    # -------

    def initialize app
      @app = app
      setup
    end

    def self.descendants
      @descendants ||= []
    end

    # Descendant tracking for inherited classes.
    def self.inherited(descendant)
      descendants << descendant
    end

    def register_command *cmds, &b
      opts = cmds.extract_options!
      handler = self
      cmds = [*cmds].flatten

      # register name
      app.command_names["!" << cmds.join(" !")] = opts[:desc]

      # register handler
      cmds.each do |cmd|
        cmd = cmd.to_s
        register_parser(/<([^>]+)> \!(.+)/i) do |res, r|
          if r[2] == "#{cmd}" || r[2].start_with?("#{cmd} ")
            catch(:handler_exit) do
              b[handler, r[1], r[2], "#{r[2]}".split(" ")[1].presence || r[1], r[2].split(" ")[1..-1], OptionParser.new]
            end
          end
        end
      end
    end

    def pmemo p
      app.ram[:players] ||= {}
      app.ram[:players][p.to_s] ||= {}
      app.ram[:players][p.to_s]
    end

    def strbool v
      v = true if ["true", "t", "1", "y", "yes", "on"].include?(v)
      v = false if ["false", "f", "0", "n", "no", "off"].include?(v)
      v
    end

    def prec p
      Player.where(nickname: p).first_or_initialize
    end

    def acl_verify p, level = 13337
      $mcl.acl_verify(p, level)
    end

    def detect_player_position p, opts = {}, &block
      opts = opts.reverse_merge(pos: "~ ~1 ~", block: "minecraft:air")
      $mcl.server.invoke %{/execute #{p} ~ ~ ~ testforblock #{opts[:pos]} #{opts[:block]}}
      async do
        Thread.current[:tries] = 0
        Thread.current[:tick] = $mcl.eman.tick
        while !pmemo(p)[:detected_pos]
          Thread.current.kill if Thread.current[:mcl_halting]
          Thread.current[:tries] += 1
          break if Thread.current[:tries] > 50 || ($mcl.eman.tick - Thread.current[:tick]) > 10
          Thread.pass
          sleep 0.1
        end

        $mcl.sync{ block.call(pmemo(p).delete(:detected_pos)) }
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
        tellm(p, {text: text, color: "red"}, {text: " (enable with '!danger on/off')", color: "yellow"})
        return true
      end
    end

    def require_dm_for_selection p, p1, p2
      !pmemo(p)[:danger_mode] && coord_dimensions(p1, p2).inject(:*) > 100_000 && require_danger_mode(p, "Selections >100k blocks require danger mode to be enabled!")
    end
  end
end
