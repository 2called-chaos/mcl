# Heatmon daemon wrapper
require "daemons"
require "fileutils"
require "active_support/core_ext"
PROJECT_ROOT = Pathname.new File.expand_path("../..", __FILE__)

# Instance
MCL_INSTANCE = ENV["MCL_INSTANCE"].presence || ENV["MCLI"].presence || "default"

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


# tick
  # - tail log file and add lines to spool (array with raw data)
  # - parse spool to command spool (parse raw data to event, save it to database and spool it for tick)
  # - tick command callbacks (call callbacks for registered event handlers)
  # - short tick all handlers (call short tick callbacks for all handlers)
  # - tick scheduled events (timers)
  # - perform late tick events (reload configuration, etc.)
