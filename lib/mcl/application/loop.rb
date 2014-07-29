module Mcl
  class Application
    module Loop
      def loop!
        prepare_loop

        loop do
          mayexit
          eman.tick!
        end
      ensure
        graceful_shutdown
      end

      def prepare_loop
        setup_event_manager # controller (ticking)
        setup_scheduler     # scheduled tasks
        setup_server        # setup server communication
        setup_handlers      # setup all handlers

        eman.ready!
      end
    end
  end
end
