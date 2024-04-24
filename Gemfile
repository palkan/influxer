source "https://rubygems.org"
gemspec

local_gemfile = "Gemfile.local"

eval_gemfile "gemfiles/rubocop.gemfile"

gem "pry-byebug", platform: :mri

if File.exist?(local_gemfile)
  eval(File.read(local_gemfile)) # rubocop:disable Lint/Eval
else
  gem 'sqlite3', '1.4', platform: :mri
  gem 'activerecord', '~> 7.0'
end
