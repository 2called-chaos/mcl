module Mcl
  class Server
    class VersionedCommand
      attr_reader :app

      def initialize app, &block
        @app = app
        @constraints = []
        block.call(self, app)
      end

      def default cmd
        @default = cmd
      end

      def before *versions, &block
        cmd = block ? block.call(self) : versions.pop
        versions.each do |v|
          @constraints << [:before, v, cmd]
        end
      end

      def since *versions, &block
        cmd = block ? block.call(self) : versions.pop
        versions.each do |v|
          @constraints << [:since, v, cmd]
        end
      end

      def after *versions, &block
        cmd = block ? block.call(self) : versions.pop
        versions.each do |v|
          @constraints << [:after, v, cmd]
        end
      end

      def between versions = {}, cmd = nil, &block
        cmd = block.call(self) if block
        versions.each do |from, upto|
          @constraints << [:between, from, upto, cmd]
        end
      end

      def compile version
        sv = mc_comparable_version(version)

        @constraints.each do |k, *a, c|
          case k
          when :before
            tv = mc_comparable_version(a[0])
            return c if sv.class == tv.class && sv < tv
          when :after
            tv = mc_comparable_version(a[0])
            return c if sv.class == tv.class && sv > tv
          when :since
            tv = mc_comparable_version(a[0])
            return c if sv.class == tv.class && sv >= tv
          when :between
            tv1 = mc_comparable_version(a[0])
            tv2 = mc_comparable_version(a[1])
            return c if sv.class == tv1.class && sv.between?(tv1, tv2)
          end
        end
        return @default
      end

      def mc_comparable_version *a
        app.handlers.first.mc_comparable_version(*a)
      end
    end
  end
end
