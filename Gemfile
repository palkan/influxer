source "https://rubygems.org"
gemspec

local_gemfile = "Gemfile.local"

gem "pry-byebug", platform: :mri

if File.exist?(local_gemfile)
  eval(File.read(local_gemfile)) # rubocop:disable Lint/Eval
else
  gem "activerecord", "~>4.2"
  gem "sqlite3", "~> 1.3.0"
end
