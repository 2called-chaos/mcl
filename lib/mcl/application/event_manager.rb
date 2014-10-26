module Mcl
  class Application
    class EventManager
      attr_reader :app, :spool, :cond, :collector, :tick, :events, :parser, :commands

      def initialize app
        @app = app
        @spool = Queue.new
        @spool.extend MonitorMixin
        @cond = @spool.new_cond
        @ready = false
        @tick = 0
        @commands = {}

        setup_parser
        spawn_collector
      end

      def setup_parser
        @parser = Classifier.new(app)
      end

      # collector is a separate thread which just tails the log file and puts the stuff in a queue.
      def spawn_collector
        app.graceful do
          app.log.debug "[SHUTDOWN] killing collector..."
          $mcl.eman.collector.try(:kill)
        end

        @collector = Thread.new do
          Thread.current.abort_on_exception = true
          sleep 1 until ready? # wait for system to boot up
          app.server.ipc_spawn
          sleep 1 # don't mess with the logger

          loop do
            begin
              app.server.ipc_read {|line| @spool << line }
            rescue Exception => e
              app.devlog "[Collector] #{e.class}: #{e.message}"
              sleep 1
            end
          end
        end
      end

      def ready?
        @ready
      end

      def ready!
        app.log.info "Entering main loop..."
        @ready = true
      end

      def atime time
        if time < 0
          "-#{atime(time.abs)}"
        elsif time < 0.001
          "< 1ms"
        elsif time > 1
          "#{time.round(3)}s"
        else
          "#{(time * 1000.0).round(0)}ms"
        end
      end

      module PreTick
        def detect_mcl_lag
          if Thread.current[:last_tick] && (Time.current - Thread.current[:last_tick]) > (app.config["tick_rate"]*2)
            diff = Time.current - Thread.current[:last_tick]
            app.log.warn "[CORE] main loop is lagging (delayed for #{diff.to_f - app.config["tick_rate"]}s)"
          end
        end

        def detect_died_minecraft_server
          if app.server.died?
            app.log.fatal "[IPC] connection to minecraft server lost after tick ##{@tick - 1}, rebooting..."
            raise Application::Reboot, "server connection lost after tick ##{@tick - 1}"
          end
        end

        def detect_reboot_request
          if $mcl_reboot
            $mcl_reboot = false
            raise Application::Reboot, "internal request"
          end
        end

        def scrub_async_threads
          if @tick % app.config["async_scrub_rate"] == 0
            app.async.select!(&:alive?)
          end
        end

        def scrub_promises
          if @tick % app.config["promise_scrub_rate"] == 0
            app.promises.select!(&:alive?)
          end
        end

        def clear_player_cache
          if @tick % app.config["player_cache_save_rate"] == 0
            app.delay { app.pman.clear_cache }
          end
        end

        def garbage_collect
          if @tick % app.config["gc_rate"] == 0
            GC.start
          end
        end
      end
      include PreTick

      module MainTick
        # check if promises meet condition or timed out
        def tick_promises
          # promises
          app.promises.each_with_index do |promise, i|
            begin
              promise.tick!
              app.promises.delete_at(i) unless promise.alive?
            rescue Exception
              app.handle_exception($!) do |ex|
                app.log.error "PromiseTickError on tick #{@tick}: (#{ex.class.name}) #{ex.message}"
              end
            end
          end
        end

        # call all handlers (shortticktime)
        def tick_handlers
          app.handlers.each do |handler|
            begin
              handler.tick!
            rescue Exception
              app.handle_exception($!) do |ex|
                app.log.error "ShortTickPerformError on tick #{@tick}: (#{ex.class.name}) #{ex.message}"
              end
            end
          end
        end

        # call delayed handlers
        def tick_delayed
          while cb = app.delayed.shift
            begin
              cb.call
            rescue Exception
              app.handle_exception($!) do |ex|
                app.log.error "DelayedPerformError on tick #{@tick}: (#{ex.class.name}) #{ex.message}"
              end
            end
          end
        end

        # process spool and call handlers accordingly
        def tick_spool &block
          while !@spool.empty?
            val = @spool.pop(true) rescue nil
            break if val.nil?
            block.call(val)

            begin
              # parse event
              app.spool_event(val.chomp)
              app.devlog "[EVENT] #{val.chomp}", scope: "event"
              evd = parser.classify(val.chomp)
            rescue Exception
              app.handle_exception($!) do |ex|
                app.log.error "EventParseError on tick #{@tick}: (#{ex.class.name}) #{ex.message}"
              end
            end
          end
        end

        # call scheduler which may invoke tasks which were delayed previously
        def tick_scheduler
          begin
            app.scheduler.tick!
          rescue Exception
            app.handle_exception($!) do |ex|
              app.log.error "SchedulerPerformError on tick #{@tick}: (#{ex.class.name}) #{ex.message}"
            end
          end
        end
      end
      include MainTick

      # main loop
      def tick!
        # raise Application::Halt, "ticklimit of 500 reached" if @tick > 500
        @tick += 1
        events, jobs, diff = 0, 0, 0
        processtime, shortticktime, delayedtime, schedulertime = nil

        app.sync do
          begin
            ticktime = Benchmark.realtime do
              # pretick
              detect_mcl_lag
              detect_died_minecraft_server
              detect_reboot_request
              scrub_async_threads
              scrub_promises
              clear_player_cache
              garbage_collect

              # process spool to events
              processtime = Benchmark.realtime do
                tick_promises
                tick_spool { events += 1 }
              end

              # short tick handlers
              shortticktime = Benchmark.realtime { tick_handlers }

              # delayed tasks
              delayedtime = Benchmark.realtime { tick_delayed }

              # tick scheduler
              schedulertime = Benchmark.realtime { jobs = tick_scheduler }
            end
          ensure
            Thread.current[:last_tick] = Time.current
            if ticktime
              diff = app.config["tick_rate"] - ticktime
              app.devlog "[T#{@tick}] #{events} events, #{jobs} jobs (RT: #{atime(ticktime)} P: #{atime(processtime)} ST: #{atime(shortticktime)} D: #{atime(delayedtime)} S: #{atime(schedulertime)} W: #{atime(diff)})", scope: "tick"
            end
          end
        end

        Thread.pass # give other threads an explicit chance to do something
        sleep diff if diff > 0 # sleep rest of tick rate if there is any left
      end
    end
  end
end
