module Mcl
  ROOT = File.expand_path("../..", __FILE__)

  def self.git_message
    `cd "#{ROOT}" && git log -1 --pretty=%B HEAD`.strip
  end

  def self.git_sha
    `cd "#{ROOT}" && git log -1 --pretty=%H HEAD`.strip
  end

  def self.windows?
    (RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/)
  end

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
      puts "/// Rebooting MCL in 5 seconds (#{$!.message}) - #{Thread.list.length} threads remain"
      sleep 5

      # Remove all references to the application instance and run GC.
      # This prevents the app from using twice the ram when rebooted.
      Handler.descendants.clear
      $mcl = app = Thread.main[:app] = nil
      GC.start

      retry
    rescue Application::Halt, SystemExit
      puts "/// MCL halted (#{$!.message}) - #{Thread.list.length} threads remain"
      exit 0
    end
  end
end
