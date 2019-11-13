source "https://www.rubygems.org"

# core
gem 'rake'
gem 'pry'
gem 'daemons'
gem 'file-tail'
gem 'httparty' # cause I got sick of stdlib
gem 'nbtfile', git: "https://github.com/2called-chaos/nbtfile.git"

# database
gem 'activerecord', '< 5.2'
gem 'sqlite3', group: :sqlite
gem 'mysql2', group: :mysql

# handler gems
root = File.expand_path("..", __FILE__)
files = Dir["#{root}/vendor/handlers/**{,/*/**}/Gemfile"].uniq.sort
files.each do |file|
  next if file.gsub("#{root}/vendor/handlers/", "").split("/").any?{|fp| fp.start_with?("__") }
  eval File.read(file)
end
