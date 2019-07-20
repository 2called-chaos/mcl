module Mcl
  class Handler
    module Shortcuts
      def server
        app.server
      end

      def eman
        app.eman
      end

      def pman
        app.pman
      end

      def pmemo p, scope = nil
        r = app.ram[:players][p.to_s] ||= {}
        scope ? (r[scope] ||= {}) : r
      end

      def prec p
        $mcl.pman.prec(p)
      end

      def acl_verify p, level = 13337
        $mcl.pman.acl_verify(p, level)
      end

      def acl_permitted p, level = 13337
        $mcl.pman.acl_permitted(p, level)
      end

      def promise opts = {}, &block
        Promise.new(app, opts, &block).tap{|p| app.promises << p }
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

      def async_safe &block
        $mcl.async_call do
          begin
            block.call
          rescue
            app.log.debug $!.message
            $!.backtrace.each {|m| app.log.debug(m) }
            app.server.traw("@a", "[ERROR] #{$!.message}", color: "red")
            app.server.traw("@a", "        #{$!.backtrace[0].to_s.gsub(ROOT, "%")}", color: "red")
          end
        end
      end

      def sync &block
        $mcl.sync(&block)
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

      def trawt *a
        $mcl.server.trawt(*a)
      end

      def schedule *a
        $mcl.scheduler.schedule(*a)
      end
    end
  end
end
