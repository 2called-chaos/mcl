module Mcl
  class Application
    module Setup
      CURRENT_CFG_VERSION = 2
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
        @logfile = Logger.new(logger_filename, 10, 1024000)
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
          @config = _load_config(@config_file)

          # apply debug
          toggle_debug @config["debug"], false
        else
          log.fatal "[SETUP] Instance `#{ARGV[0]}' has no corresponding config file `#{@config_file}'"
          exit 1
        end
      end

      def _load_config config_file
        config = YAML.load_file(config_file)
        raise unless config

        # config version
        if config["version"]
          if config["version"] < CURRENT_CFG_VERSION
            raise "config outdated (#{config["version"]} < #{CURRENT_CFG_VERSION}), please migrate from the updated `config/default.example.yml'"
          end
        else
          raise "no config version specified, please migrate from the updated `config/default.example.yml'"
        end

        # fix paths
        if config["database"]["adapter"] == "sqlite3"
          dbfile = config["database"]["database"].presence || "vendor/data/#{@instance}.sqlite"
          config["database"]["database"] = Pathname.new(ROOT).join(dbfile).to_s
        end

        config
      rescue
        raise "Failed to load config, is the syntax correct? (#{$!.message}"
      end

      def reload_config
        config = _load_config(@config_file)
        toggle_debug config["debug"], false
        @config = config
      end

      def setup_database
        log.debug "[SETUP] Establishing database connection (#{@config["database"]["adapter"]})..."
        ActiveRecord::Base.logger = @config["dev"] && @config["devchannels"].include?("active_record") ? @logger : nil
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
          Player.online.each{|p| pman.logout_user(p.nickname) } unless $_ipc_reattach
          pman.clear_cache
        end

        @pman = PlayerManager.new(self)
        @pman.cleanup
      end

      def setup_handlers load_files = true
        @handlers = []
        @command_acls = {}
        @command_names = {}
        if load_files
          files = (Dir["#{ROOT}/lib/mcl/handlers/**{,/*/**}/*.rb"] + Dir["#{ROOT}/vendor/handlers/**{,/*/**}/*.rb"]).uniq.sort
          files.reject do |file|
            file.gsub("#{ROOT}/vendor/handlers/", "").split("/").any?{|fp| fp.start_with?("__") }
          end.each{|f| load f }
        end

        Mcl::Handler.descendants.uniq.each do |klass|
          devlog "[SETUP] Setting up handler `#{klass.name}'", scope: "plugin_load"
          @handlers << klass.new(self)
        end

        @handlers.each do |handler|
          devlog "[SETUP] Initializing handler `#{handler.class.name}'", scope: "plugin_load"
          handler.init
        end
        log.debug "[SETUP] #{@command_names.count} commands registered..."
      end

      def setup_console
        graceful do
          unless @console_server.halting
            log.debug "[SHUTDOWN] Stopping console socket server..."
            @console_server.shutdown!
            @log.remove_target @console_server.log
          end
        end

        log.debug "[SETUP] Starting console socket server..."
        @console_server = ConsoleServer.new(self)
        @console_server.spawn
        @log.add_target @console_server.log
      end

      def trap_signals
        Signal.trap("INT") {|sig| shutdown!("#{Signal.signame(sig)}") }
        Signal.trap("TERM") {|sig| shutdown!("#{Signal.signame(sig)}") }
        Signal.trap("TSTP") {|sig| shutdown!("#{Signal.signame(sig)}") } unless Mcl.windows?
        Signal.trap("USR1") {|sig| $debug_mode_changed = !debug? } unless Mcl.windows?

        graceful do
          log.debug "[SHUTDOWN] Releasing signal traps..."
          Signal.trap("INT", "DEFAULT")
          Signal.trap("TERM", "DEFAULT")
          Signal.trap("TSTP", "DEFAULT") unless Mcl.windows?
          Signal.trap("USR1", "DEFAULT") unless Mcl.windows?
        end
      end

      def prepare_loop
        setup_console       # socket server for console clients
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
