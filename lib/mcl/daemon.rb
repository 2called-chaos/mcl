module Mcl
  ["mcl", "mcl/core"].each{|l| require "#{File.expand_path("../..", __FILE__)}/#{l}" }
  run(ENV["MCL_INSTANCE"].presence || ENV["MCLI"].presence || "default")
end
