module Mcl
  class HMclCBSBuilder
    class Printer
      attr_reader :stats

      def initialize blueprint
        @blueprint = blueprint
        @building = false
        @canceled = false
        @stopped = false
        @pos = false
        @air = true
        @pc = "xyz"
        reset_stats
        run_hooks(:load)
      end

      # print callbacks
      %w[on_compile_start on_compile_end on_compile_error on_build_start on_build_end on_build_error].each do |callback|
        define_method(callback) do |&block|
          instance_variable_set(:"@#{callback}", block)
        end
      end

      # accessors
      [:building, :canceled, :stopped, :pos, :pc, :air].each do |meth|
        define_method(:"#{meth}?") { __send__(meth).present? }
        attr_accessor meth
      end

      def reset_stats
        @stats = { blocks_placed: 0, blocks_ignored: 0, blocks_processed: 0 }
      end

      def progress
        ((stats[:blocks_processed] / _.volume.to_f) * 100).round(2)
      end

      def start_pos pc = @pc
        return false unless @pos
        @pos.dup.tap do |pos|
          xd, yd, zd = blueprint.dimensions
          pos[0] -= xd - 1 if pc["X"]
          pos[1] -= yd - 1 if pc["Y"]
          pos[2] -= zd - 1 if pc["Z"]
        end
      end

      def end_pos pc = @pc
        return false unless @pos
        @pos.dup.tap do |pos|
          xd, yd, zd = blueprint.dimensions
          pos[0] += xd - 1 if pc["x"]
          pos[1] += yd - 1 if pc["y"]
          pos[2] += zd - 1 if pc["z"]
        end
      end

      def blueprint
        @blueprint
      end
      alias_method :_, :blueprint

      def compile vcset
        return false unless @pos
        _.compile(start_pos, vcset)
      end

      def cancel &callback
        return false if !@building || @canceled
        @canceled = true
        # sleep 0.1 until @stopped
        callback.call if callback
      end

      def run_hooks type
        _.compile_hooks(type, start_pos, end_pos).each do |cmd|
          $mcl.server.invoke(cmd)
        end
      end

      def print handler
        return false unless @pos
        reset_stats
        @canceled = false
        @stopped = false
        @building = true

        # versions
        vcset = nil
        handler.version_switch do |v|
          v.default { vcset = "1.12" }
          v.since("1.13", "17w45a") { vcset = "1.13" }
        end

        handler.async do
          begin
            cdata, compiletime, buildtime = nil, nil, nil

            # compile
            begin
              compiletime = Benchmark.realtime do
                @on_compile_start.try(:call)
                cdata = compile(vcset) || raise("no position defined, abort compile")
              end
              @on_compile_end.try(:call, compiletime)
            rescue StandardError => ex
              @on_compile_error.try(:call, compiletime, ex)
            end

            # build
            begin
              buildtime = Benchmark.realtime do
                run_hooks(:before)
                @on_build_start.try(:call)
                until cdata.empty?
                  # checks
                  raise "canceled" if @canceled
                  raise "MCL is shutting down" if Thread.current[:mcl_halting]
                  raise "IPC down" unless $mcl.server.alive?

                  # place(!) 123 blocks and then Thread.pass
                  $mcl.sync do
                    placed = 0

                    while placed <= 123 && !cdata.empty?
                      ci = cdata.shift
                      next if ci.blank?

                      if !air? || ci =~ /\A\/setblock ([0-9~]+) ([0-9~]+) ([0-9~]+) (minecraft:)?(cave_|void_)?air\z/i
                        @stats[:blocks_ignored] += 1
                      else
                        # invoke
                        $mcl.server.invoke(ci)

                        # stats
                        placed += 1
                        @stats[:blocks_placed] += 1

                        # catchup time for server
                        sleep 3 if @stats[:blocks_placed] % 2500 == 0
                      end
                      @stats[:blocks_processed] += 1
                    end
                  end
                  sleep 0.0001
                  Thread.pass
                end
              end
              run_hooks(:after)
              @on_build_end.try(:call, compiletime)
            rescue StandardError => ex
              @on_build_error.try(:call, compiletime, cdata.length, ex)
            end
          ensure
            @stopped = true
            @building = false
          end
        end
      rescue
        @stopped = true
        @building = false
      end
    end
  end
end
