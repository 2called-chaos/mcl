module Mcl
  class Application
    attr_reader :log, :instance, :config, :ram, :handlers, :eman, :server, :scheduler, :acl

    include Setup
    include Loop

    def initialize instance
      @mutex = Monitor.new
      @instance = instance
      @graceful = []
      @exit_code = 0
      @acl = {}
      @ram = {
        exceptions: []
      }

      begin
        setup_logger
        load_config
        trap_signals
        setup_database
        log.info "[SETUP] Core ready!"
      rescue Exception
        Thread.main[:mcl_original_exception] = $!
        if $!.is_a?(Interrupt)
          log.warn "Interrupted!"
        else
          log.fatal "FATAL EXCEPTION! (#{$!.class.name}: #{$!.message})"
        end
        graceful_shutdown
        Thread.main[:mcl_original_exception] = nil
        raise
      end
    end

    def synchronize &b
      @mutex.synchronize(&b)
    end

    def graceful &block
      @graceful.unshift block
    end

    def graceful_shutdown
      log.debug "Performing graceful shutdown"
      @graceful.each do |task|
        begin
          task.call
        rescue
          warn $!.message
          $!.backtrace.each{|l| warn(l) }
        end
      end
    end

    def debug?
      @logger.debug?
    end

    def toggle_debug val = nil, announce = true
      is = val.nil? ? debug? : !val

      if is
        log.debug "[!] Debug mode disabled" if announce
        log.level = Logger::INFO
      else
        log.level = Logger::DEBUG
        log.debug "[!] Debug mode enabled" if announce
      end
    end

    # define point where application or unsafe can safely exit when term signal is received
    def mayexit
      if !$debug_mode_changed.nil?
        toggle_debug $debug_mode_changed
        $debug_mode_changed = nil
      end
      return true if !@shutdown
      exit @exit_code
    end

    def handle_exception ex, &handler
      return false if ex.is_a?(Mcl::Application::Halt)
      return false if ex.is_a?(Mcl::Application::Reboot)
      return false if ex.is_a?(SystemExit)
      @ram[:exceptions] << ex
      @ram[:exceptions].shift while @ram[:exceptions].length > 10
      handler.call(ex)
      true
    end

    # Mark application for termination.
    # This method is not thread safe in terms of keeping the correct signal.
    # It will shutdown under any circumstances.
    def shutdown! sig = "Shutting down"
      unless @shutdown
        @exit_code = 2
        @shutdown = "#{sig}"
        puts "Shutting down, please wait... (#{@shutdown})"
      end
    end
  end
end
