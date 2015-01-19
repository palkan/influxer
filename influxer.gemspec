$:.push File.expand_path("../lib", __FILE__)

require "influxer/version"

Gem::Specification.new do |s|
  s.name        = "influxer"
  s.version     = Influxer::VERSION
  s.authors     = ["Vlad Dem"]
  s.email       = ["dementiev.vm@gmail.com"]
  s.homepage    = "http://github.com/palkan/influxer"
  s.summary     = "InfluxDB for Rails"
  s.description = "InfluxDB the Rails way"
  s.license     = "MIT"

  s.files         = `git ls-files`.split($/)
  s.require_paths = ["lib"]
  
  s.add_runtime_dependency "rails", '~> 4.0'
  s.add_dependency "influxdb", "~> 0.1.0", ">= 0.1.8"

  s.add_development_dependency "timecop"
  s.add_development_dependency "simplecov", ">= 0.3.8"

  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'pry-byebug'
  s.add_development_dependency "rspec", "~> 3.1.0"
  s.add_development_dependency "rspec-rails", "~> 3.1.0"
end
