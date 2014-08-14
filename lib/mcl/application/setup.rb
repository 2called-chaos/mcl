module Mcl
  class Application
    module Setup
      include DbSchema

      def setup_logger
        @logger = Logger.new(STDOUT)
        @logger.instance_variable_set(:"@mcl_uncloseable", true)
        @logfile = Logger.new("#{ROOT}/log/console.log", 10, 1024000)
        @logfile.progname = "mcld"
        @log = MultiIO.new(@logger, @logfile)
        graceful do
          @log.info "[SHUTDOWN] Halting logger..."
          @log.close
        end
        log.info "--------------------------------------------------"
        log.info "[SETUP] Logger ready!"
      end

      def load_config
        @config_file = "#{ROOT}/config/#{@instance}.yml"

        if FileTest.exist?(@config_file)
          log.info "[SETUP] Using #{@config_file}"
          begin
            @config = YAML.load_file(@config_file)
            raise unless @config

            # fix paths
            if @config["database"]["adapter"] == "sqlite3"
              @config["database"]["database"] = Pathname.new(ROOT).join(@config["database"]["database"]).to_s
            end

            # apply debug
            toggle_debug @config["debug"], false
          rescue
            raise "Failed to load config, is the syntax correct?"
          end
        else
          log.fatal "[SETUP] Instance `#{ARGV[0]}' has no corresponding config file `#{@config_file}'"
          exit 1
        end
      end

      def setup_database
        log.debug "[SETUP] Establishing database connection (#{@config["database"]["adapter"]})..."
        ActiveRecord::Base.logger = @log
        ActiveRecord::Base.establish_connection(@config["database"])
        log.debug "[SETUP] Running migrations..."
        define_database_schema

        graceful do
          log.debug "[SHUTDOWN] Closing database connection..."
          ActiveRecord::Base.connection.close
        end

        log.info "[SETUP] Database ready!"
      end

      def setup_async
        graceful do
          log.debug "[SHUTDOWN] Waiting for aSync threads to end (#{async.count})..."

          # marking threads so they can mayexit
          async.each{|t| t[:mcl_halting] = true }

          # wait 15 seconds for threads to exit
          begin
            Timeout::timeout(15) { async.each(&:join) }
          end
        end

        log.debug "[SETUP] Threaded aSync ready..."
      end

      def setup_event_manager
        @eman = EventManager.new(self)
      end

      def setup_server
        @server = Server.new(self)
      end

      def setup_scheduler
        @scheduler = Scheduler.new(self)
      end

      def setup_handlers
        @handlers = []
        @command_names = []
        files = Dir["#{ROOT}/lib/mcl/handlers/**/*.rb"] + Dir["#{ROOT}/handlers/**/*.rb"]
        files.reject{|f| File.basename(f).start_with?("__") }.each{|f| load f }

        Mcl::Handler.descendants.uniq.each do |klass|
          @handlers << klass.new(self)
        end

        @handlers.each(&:init)
      end

      def trap_signals
        Signal.trap("INT") {|sig| shutdown!("#{Signal.signame(sig)}") }
        Signal.trap("TERM") {|sig| shutdown!("#{Signal.signame(sig)}") }
        Signal.trap("TSTP") {|sig| shutdown!("#{Signal.signame(sig)}") }
        Signal.trap("USR1") {|sig| $debug_mode_changed = !debug? }

        graceful do
          log.debug "[SHUTDOWN] Releasing signal traps..."
          Signal.trap("INT", "DEFAULT")
          Signal.trap("TERM", "DEFAULT")
          Signal.trap("TSTP", "DEFAULT")
          Signal.trap("USR1", "DEFAULT")
        end
      end
    end
  end
end
