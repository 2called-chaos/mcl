module Mcl
  class Handler
    attr_reader :app

    def setup
      # called on creation
    end

    def init
      # called when all handlers have went through their setup
    end

    def tick!
      # called on every tick (should be fast)
    end

    # -------


    def self.descendants
      @descendants ||= []
    end

    # Descendant tracking for inherited classes.
    def self.inherited(descendant)
      descendants << descendant
    end


    def initialize app
      @app = app
      setup
    end

    def server
      app.server
    end

    def eman
      app.eman
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

    def register_parser *a, &b
      eman.parser.register(*a, &b)
    end

    def register_pre_parser *a, &b
      eman.parser.register_pre(*a, &b)
    end

    def gm *a
      $mcl.server.gm(*a)
    end

    def traw *a
      $mcl.server.traw(*a)
    end

    def trawm *a
      $mcl.server.trawm(*a)
    end

    def strbool v
      v = true if ["true", "t", "1", "y", "yes"].include?(v)
      v = false if ["false", "f", "0", "n", "no"].include?(v)
      v
    end

    def prec p
      Player.where(nickname: p).first_or_initialize
    end

    def acl_verify p, level = 13337
      $mcl.acl_verify(p, level)
    end

    def async &block
      $mcl.async_call(&block)
    end

    def indicate_coord p, coord, type = nil
      coord = coord.join(" ") if coord.respond_to?(:each)
      parts = coord.split(" ").map(&:to_f)
      case type.to_s.strip
        when "p", "particle" then $mcl.server.invoke "/particle reddust #{coord} 0 0 0 1 1000 force"
        when "b", "barrier" then $mcl.server.invoke "/particle barrier #{coord} 0 0 0 1 1 force"
        when "crystal" then $mcl.server.invoke "/summon EnderCrystal #{parts[0]} #{parts[1] - 0.5} #{parts[2]}"
        when "c", "cross"
          $mcl.server.invoke "/particle reddust #{coord} 1 0 0 1 1000 force"
          $mcl.server.invoke "/particle reddust #{coord} 0 1 0 1 1000 force"
          $mcl.server.invoke "/particle reddust #{coord} 0 0 1 1 1000 force"
        else $mcl.server.invoke "/particle largeexplode #{coord} 0 0 0 1 10 force"
      end
    end
  end
end
