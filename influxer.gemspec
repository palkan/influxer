$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "influxer/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "influxer"
  s.version     = Influxer::VERSION
  s.authors     = ["Vlad Dem"]
  s.email       = []
  s.homepage    = ""
  s.summary     = "InfluxDB support for Rails"
  s.description = "InfluxDB the Rails way"
  s.license     = "MIT"

  s.files         = `git ls-files`.split($/)
  s.require_paths = ["lib"]
  
  s.add_dependency "rails", ">= 4.0.0"
  s.add_dependency "influxdb", "~> 0.1.8"

  s.add_development_dependency "timecop"
  s.add_development_dependency "simplecov", ">= 0.3.8"
  s.add_development_dependency "rspec", "~> 3.0.0"
  s.add_development_dependency "rspec-rails", "~> 3.0.0"
end
