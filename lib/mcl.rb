module Mcl
  ROOT = File.expand_path("../..", __FILE__)

  # allow reloadable classes (dirty)
  def self.reloadable konst, parent = nil
    parent ||= Mcl
    if parent.const_defined?(konst)
      parent.send(:remove_const, konst)
      # puts "#{konst} reloaded"
    else
      # puts "#{konst} first load"
    end
  end

  # sync output
  STDOUT.sync = true

  # init dependencies
  Bundler.require

  # core dependencies
  require "open3"
  require "yaml"
  require "optparse"
  require "benchmark"
  require "thread"
  require "monitor"
  require "digest/sha1"

  # gems
  require "active_record"

  # application
  "#{ROOT}/lib/mcl".tap do |lib|
    # require "#{lib}/version"
    require "#{lib}/multi_io"
    require "#{lib}/command"
    require "#{lib}/handler"
    require "#{lib}/listener"
    require "#{lib}/player_manager"
    require "#{lib}/server/io"
    require "#{lib}/server/getters"
    require "#{lib}/server/ipc/logfile"
    require "#{lib}/server/ipc/screen"
    require "#{lib}/server/ipc/tmux"
    require "#{lib}/server/ipc/wrap"
    require "#{lib}/server"
    require "#{lib}/models/event"
    require "#{lib}/models/event/unknown"
    require "#{lib}/models/event/boot"
    require "#{lib}/models/event/chat"
    require "#{lib}/models/event/clientstate"
    require "#{lib}/models/event/exception"
    require "#{lib}/models/event/log"
    require "#{lib}/models/event/uauth"
    require "#{lib}/classifier/parsing"
    require "#{lib}/classifier/result"
    require "#{lib}/classifier"
    require "#{lib}/application/halt"
    require "#{lib}/application/reboot"
    require "#{lib}/application/event_manager"
    require "#{lib}/application/scheduler"
    require "#{lib}/application/loop"
    require "#{lib}/application/db_schema"
    require "#{lib}/application/setup"
    require "#{lib}/application"
  end

  # ------------------------

  # main dispatch
  begin
    $mcl = app = Thread.main[:app] = Application.new(ARGV[0].presence || "default")
    app.loop!
  rescue Application::Reboot
    puts "/// Rebooting MCL in 5 seconds (#{$!.message})"
    sleep 5

    # Remove all references to the application instance and run GC.
    # This prevents the app from using twice the ram when rebooted.
    $mcl = app = Thread.main[:app] = nil
    GC.start

    retry
  rescue Application::Halt, SystemExit
    puts "/// MCL halted (#{$!.message})"
    exit 0
  end
end
