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
        @collector = Thread.new do
          Thread.current.abort_on_exception = true
          sleep 1 until ready? # wait for system to boot up
          app.server.ipc_spawn
          sleep 1 # don't mess with the logger

          loop do
            begin
              app.server.ipc_read {|line| @spool << line }
            rescue Exception
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

      # that is the most awful method I've ever written, I swear!
      def tick!
        # raise Application::Halt, "ticklimit of 500 reached" if @tick > 500

        app.sync do
          begin
            @tick += 1
            events, jobs = 0, 0
            processtime, shortticktime, delayedtime, schedulertime = nil

            ticktime = Benchmark.realtime do
              # detect MCL lag
              if Thread.current[:last_tick] && (Time.current - Thread.current[:last_tick]) > (app.config["tick_rate"]*2)
                diff = Time.current - Thread.current[:last_tick]
                app.log.warn "[CORE] main loop is lagging (delayed for #{diff.to_f - app.config["tick_rate"]}s)"
              end

              # detect died minecraft server
              if app.server.died?
                app.log.fatal "[IPC] connection to minecraft server lost after tick ##{@tick - 1}, rebooting..."
                raise Application::Reboot, "server connection lost after tick ##{@tick - 1}"
              end

              # detect reboot request
              if $mcl_reboot
                $mcl_reboot = false
                raise Application::Reboot, "internal request"
              end

              # scrub async threads
              if @tick % app.config["async_scrub_rate"] == 0
                app.async.select!(&:alive?)
              end

              # scrub promises
              if @tick % app.config["promise_scrub_rate"] == 0
                app.promises.select!(&:alive?)
              end

              # player cache
              if @tick % app.config["player_cache_save_rate"] == 0
                app.delay { app.pman.clear_cache }
              end

              # process spool to events
              processtime = Benchmark.realtime do
                begin
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

                  # actual spool
                  while !@spool.empty?
                    val = @spool.pop(true) rescue nil
                    break if val.nil?
                    events += 1

                    # handle stuff
                    begin
                      # parse event
                      evd = parser.classify(val.chomp)
                    rescue Exception
                      app.handle_exception($!) do |ex|
                        app.log.error "EventParseError on tick #{@tick}: (#{ex.class.name}) #{ex.message}"
                      end
                    end
                  end
                end
              end

              # short tick handlers
              shortticktime = Benchmark.realtime do
                begin
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
              end

              # delayed tasks
              delayedtime = Benchmark.realtime do
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

              # tick scheduler
              schedulertime = Benchmark.realtime do
                begin
                  jobs = app.scheduler.tick!
                rescue Exception
                  app.handle_exception($!) do |ex|
                    app.log.error "SchedulerPerformError on tick #{@tick}: (#{ex.class.name}) #{ex.message}"
                  end
                end
              end
            end
          ensure
            Thread.current[:last_tick] = Time.current
            if ticktime
              diff = app.config["tick_rate"] - ticktime
              app.devlog "[T#{@tick}] #{events} events, #{jobs} jobs (RT: #{atime(ticktime)} P: #{atime(processtime)} ST: #{atime(shortticktime)} D: #{atime(delayedtime)} S: #{atime(schedulertime)} W: #{atime(diff)})"

              # sleep and give the collector a explicit chance to do something
              Thread.pass

              # sleep rest of time if there is any left
              sleep diff if diff > 0
            end
          end
        end
      end
    end
  end
end
