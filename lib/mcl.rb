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

  # ------------------------

  # main dispatch
  def self.run instance
    begin
      $mcl = app = Thread.main[:app] = Application.new(instance)
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
end
