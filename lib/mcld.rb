# Heatmon daemon wrapper
require "fileutils"
require "daemons"
require "active_support/core_ext"
PROJECT_ROOT = Pathname.new File.expand_path("../..", __FILE__)

# Ensure directories
begin
  FileUtils.mkdir_p("#{PROJECT_ROOT}/log")
  FileUtils.mkdir_p("#{PROJECT_ROOT}/tmp")
  FileUtils.mkdir_p("#{PROJECT_ROOT}/data")
rescue Errno::EPERM
  $stderr.puts "Can't create `log/' and/or `tmp/' and/or `data/' directory. Permissons? (Errno::EPERM)"
  exit 1
end

# Run daemon
Daemons.run("#{PROJECT_ROOT}/lib/mcl.rb",
  app_name: "mcld",
  dir_mode: :normal,               # use absolute path
  dir: "#{PROJECT_ROOT}/tmp",      # pid directory
  log_output: true,                # log application output
  log_dir: "#{PROJECT_ROOT}/log",  # log directory
  backtrace: true,                 # log backtrace on crash
  multiple: true,                  # allow only 1 instance
  monitor: true,                   # restart app on crash
  force_kill_waittime: 90          # wait before killing
)


# tick
  # - tail log file and add lines to spool (array with raw data)
  # - parse spool to command spool (parse raw data to event, save it to database and spool it for tick)
  # - tick command callbacks (call callbacks for registered event handlers)
  # - short tick all handlers (call short tick callbacks for all handlers)
  # - tick scheduled events (timers)
  # - perform late tick events (reload configuration, etc.)
