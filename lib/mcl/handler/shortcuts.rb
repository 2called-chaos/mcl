module Mcl
  class Handler
    module Shortcuts
      def server
        app.server
      end

      def eman
        app.eman
      end

      def pmemo p
        app.ram[:players][p.to_s] ||= {}
      end

      def prec p
        app.ram[:tick][:players][p] ||= Player.where(nickname: p).first_or_initialize
      end

      def register_parser *a, &b
        eman.parser.register(*a, &b)
      end

      def register_pre_parser *a, &b
        eman.parser.register_pre(*a, &b)
      end

      def register_command *a, &b
        eman.parser.register_command(self, *a, &b)
      end

      def async &block
        $mcl.async_call(&block)
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
    end
  end
end
