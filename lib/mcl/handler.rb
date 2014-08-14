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
      handler = self
      [*cmds].flatten.each do |cmd|
        cmd = cmd.to_s
        register_parser(/<([^>]+)> \!(.+)/i) do |res, r|
          if r[2] == "#{cmd}" || r[2].start_with?("#{cmd} ")
            catch(:handler_exit) do
              b[handler, r[1], r[2], "#{r[2]}".split(" ")[1].presence || r[1], OptionParser.new]
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
  end
end
