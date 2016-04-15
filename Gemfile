source "https://www.rubygems.org"

# core
gem 'rake'
gem 'pry'
gem 'daemons'
gem 'file-tail'
gem 'nbtfile', git: "https://github.com/2called-chaos/nbtfile.git"

# database
gem 'activerecord'
gem 'sqlite3', group: :sqlite
gem 'mysql2', group: :mysql

# handler gems
Dir["#{File.expand_path("..", __FILE__)}/vendor/handlers/**/Gemfile"].each do |file|
  eval File.read(file)
end
