module Mcl
  class Application
    class EventManager
      attr_reader :app, :spool, :cond, :collector, :tick, :events, :parser, :commands, :listener

      def initialize app
        @app = app
        @spool = Queue.new
        @spool.extend MonitorMixin
        @cond = @spool.new_cond
        @ready = false
        @tick = 0
        @commands = {}
        @listener = {}

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
          "#{time.round(5)}s"
        else
          "#{(time * 1000.0).round(0)}ms"
        end
      end

      # that is the most awful method I've ever written, I swear!
      def tick!
        # if @tick > 500
          # raise Application::Halt, "ticklimit of 500 reached"
        # end

        begin
          @tick += 1
          events, jobs = 0, 0
          parsetime, dispatchtime, shortticktime, schedulertime = nil

          ticktime = Benchmark.realtime do
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

            # parse spool to events
            begin
              parsetime = Benchmark.realtime do
                while !@spool.empty?
                  val = @spool.pop(true) rescue nil
                  break if val.nil?
                  events += 1

                  # handle stuff
                  begin
                    # parse event
                    evd = parser.classify(val.chomp)

                    if evd.append?
                      # append event data to last event
                      if @last_event
                        @last_event.append!(evd)
                      else
                        app.log.error "EventAppendError on tick #{@tick}: encountered append call with no @last_event present"
                      end
                    else
                      new_event = Event.build_from_classification(evd)
                      begin
                        # new_event.save!
                        @last_event = new_event
                        # if !evd.classified?
                        #   app.log.debug "Ignored unclassifiable event ##{new_event.id}"
                        # end
                      rescue Exception
                        app.handle_exception($!) do |ex|
                          app.log.error "EventParseError on tick #{@tick}: (#{ex.class.name}) #{ex.message}"
                        end
                      end
                    end
                  rescue Exception
                    app.handle_exception($!) do |ex|
                      app.log.error "EventParseError on tick #{@tick}: (#{ex.class.name}) #{ex.message}"
                    end
                  end
                end
              end
            end

            # dispatch events to handlers
            begin
              dispatchtime = Benchmark.realtime do
                #
              end
            ensure
            end

            # short tick handlers
            begin
              shortticktime = Benchmark.realtime do
                #
              end
            ensure
            end

            # tick scheduler
            begin
              schedulertime = Benchmark.realtime do
                #
              end
            ensure
            end
          end
        ensure
          if ticktime
            diff = app.config["tick_rate"] - ticktime
            # app.log.debug "[T#{@tick}] #{events} events, #{jobs} jobs (RT: #{atime(ticktime)} P: #{atime(parsetime)} D: #{atime(dispatchtime)} ST: #{atime(shortticktime)} S: #{atime(schedulertime)} W: #{atime(diff)})"

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
