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

      def acl_verify p, level = :admin, silent = false
        $mcl.pman.acl_verify(p, level, silent)
      end

      def acl_permitted p, level = :admin
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

      def gm *a, **kw, &b
        $mcl.server.gm(*a, **kw, &b)
      end

      def traw *a, **kw, &b
        $mcl.server.traw(*a, **kw, &b)
      end

      def trawm *a, **kw, &b
        $mcl.server.trawm(*a, **kw, &b)
      end

      def trawt *a, **kw, &b
        $mcl.server.trawt(*a, **kw, &b)
      end

      def format_number *a, **kw, &b
        $mcl.server.format_number(*a, **kw, &b)
      end

      def human_bytes *a, **kw, &b
        $mcl.server.human_bytes(*a, **kw, &b)
      end

      def schedule *a, **kw, &b
        $mcl.scheduler.schedule(*a, **kw, &b)
      end
    end
  end
end
