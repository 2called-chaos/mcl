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

    def register_command cmd, &b
      handler = self
      register_parser(/<([^>]+)> \!(.+)/i) do |res, r|
        if r[2] == "#{cmd}" || r[2].start_with?("#{cmd} ")
          b[handler, r[1], r[2], "#{r[2]}".split(" ")[1].presence || r[1], OptionParser.new]
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
  end
end
