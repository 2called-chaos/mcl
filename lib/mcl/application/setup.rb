module Mcl
  class Application
    module Setup
      include DbSchema

      def ensure_directories
        begin
          %w[log tmp vendor/data].each{|dir| FileUtils.mkdir_p("#{ROOT}/#{dir}") }
        rescue Errno::EPERM
          $stderr.puts "Can't create `log/' and/or `tmp/' and/or `vendor/data/' directory. Permissons? (Errno::EPERM)"
          exit 1
        end
      end

      def setup_logger
        @logger = Logger.new(STDOUT)
        @logger.instance_variable_set(:"@mcl_uncloseable", true)
        @logfile = Logger.new("#{ROOT}/log/console_#{@instance}.log", 10, 1024000)
        @logfile.progname = "mcld_#{@instance}"
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
              dbfile = @config["database"]["database"].presence || "vendor/data/#{@instance}.sqlite"
              @config["database"]["database"] = Pathname.new(ROOT).join(dbfile).to_s
            end

            # apply debug
            toggle_debug @config["debug"], false
          rescue
            raise "Failed to load config, is the syntax correct? (#{$!.message}"
          end
        else
          log.fatal "[SETUP] Instance `#{ARGV[0]}' has no corresponding config file `#{@config_file}'"
          exit 1
        end
      end

      def setup_database
        log.debug "[SETUP] Establishing database connection (#{@config["database"]["adapter"]})..."
        ActiveRecord::Base.logger = @config["dev"] && @config["attach_ar_logger"] ? @logger : nil
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
          rescue
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

      def setup_player_manager
        graceful do
          log.info "[SHUTDOWN] Saving players..."
          Player.online.each{|p| pman.logout_user(p.nickname) }
          pman.clear_cache
        end

        @pman = PlayerManager.new(self)
        @pman.cleanup
      end

      def setup_handlers load_files = true
        @handlers = []
        @command_names = {}
        if load_files
          files = Dir["#{ROOT}/lib/mcl/handlers/**/*.rb"] + Dir["#{ROOT}/vendor/handlers/**/*.rb"]
          files.reject{|f| File.basename(f).start_with?("__") }.each{|f| load f }
        end

        Mcl::Handler.descendants.uniq.each do |klass|
          @handlers << klass.new(self)
        end

        @handlers.each(&:init)
        log.debug "[SETUP] #{@command_names.count} commands registered..."
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

      def prepare_loop
        setup_event_manager # controller (ticking)
        setup_scheduler     # scheduled tasks
        setup_server        # setup server communication
        setup_handlers      # setup all handlers
        pman.acl_reload

        eman.ready!
      end
    end
  end
end
