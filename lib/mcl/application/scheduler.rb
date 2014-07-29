module Mcl
  class Application
    class Scheduler
      attr_reader :app

      def initialize app
        @app = app
      end

      def schedule time, &task
        Task.create(run_at: time, handler: Marshal.dump(task))
      end

      def tick!
        # Task.overdue.each do |task|

        # end
      end
    end
  end
end
