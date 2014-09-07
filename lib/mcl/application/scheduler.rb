module Mcl
  class Application
    class Scheduler
      attr_reader :app, :hibernating

      def initialize app
        @app = app
        @hibernating = false
        @last_checked = app.eman.tick
      end

      def schedule name, time, task
        Task.create(name: name, run_at: time, handler: task.to_yaml)
        @hibernating = false
      end

      def tick!
        r = 0
        if @hibernating
          @hibernating = false if (app.eman.tick - @last_checked) > app.config["scheduler_dehibernation_rate"]
        else
          if app.eman.tick % 4 == 0
            r = perform_overdue!
            @hibernating = Task.count == 0
          end
        end
        r
      end

      def perform_overdue!
        @last_checked = app.eman.tick
        Task.overdue.each do |task|
          begin
            YAML.load(task.handler).perform!
          ensure
            task.destroy
          end
        end.count
      end
    end
  end
end
