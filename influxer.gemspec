# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("../lib", __FILE__)

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

  s.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  s.require_paths = ["lib"]

  s.add_dependency "activemodel", '>= 3.2.0'
  s.add_dependency "influxdb", "~> 0.3"
  s.add_dependency "anyway_config", "~> 1.0"

  s.add_development_dependency "timecop"
  s.add_development_dependency "simplecov", ">= 0.3.8"
  s.add_development_dependency 'rake', '~> 10.1'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'activerecord', '>= 3.2.0'
  s.add_development_dependency 'pry-byebug'
  s.add_development_dependency "rspec", ">= 3.1.0"
  s.add_development_dependency "webmock", "~> 2.1"
  s.add_development_dependency "rubocop", "~> 0.49"
end
