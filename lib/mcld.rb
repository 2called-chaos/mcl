# daemon wrapper
require "daemons"
require "fileutils"
require "active_support"
require "active_support/core_ext"
PROJECT_ROOT = Pathname.new File.expand_path("../..", __FILE__)

# Instance
MCL_INSTANCE = ENV["MCL_INSTANCE"].presence || ENV["MCLI"].presence || "default"

if ARGV[0] == "console" || ARGV[0] == "c"
  STDOUT.sync = true
  ["mcl", "mcl/core"].each{|l| require "#{PROJECT_ROOT}/lib/#{l}" }
  raise "moep"
  Mcl::ConsoleClient.new.dispatch(MCL_INSTANCE)
else
  # Require elevated privileges on windows
  require "#{PROJECT_ROOT}/lib/mcl"
  if Mcl.windows?
    def running_in_admin_mode?
      system("net session >nul 2>&1")
    end

    if !running_in_admin_mode?
      puts "========================================================"
      puts "= MCL must be started from an elevated command prompt! ="
      print "========================================================"
      exit 1
    end
  end

  # Ensure directories
  FileUtils.mkdir_p("#{PROJECT_ROOT}/tmp")
  FileUtils.mkdir_p("#{PROJECT_ROOT}/log")

  # Run daemon
  Daemons.run("#{PROJECT_ROOT}/lib/mcl/daemon.rb",
    app_name: "mcld_#{MCL_INSTANCE}",
    dir_mode: :normal,               # use absolute path
    dir: "#{PROJECT_ROOT}/tmp",      # pid directory
    log_output: true,                # log application output
    log_dir: "#{PROJECT_ROOT}/log",  # log directory
    backtrace: true,                 # log backtrace on crash
    multiple: false,                 # allow only 1 instance
    monitor: true,                   # restart app on crash
    force_kill_waittime: 90          # wait before killing
  )
end
