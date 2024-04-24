# frozen_string_literal: true

require_relative "lib/influxer/version"

Gem::Specification.new do |s|
  s.name = "influxer"
  s.version = Influxer::VERSION
  s.authors = ["Vlad Dem"]
  s.email = ["dementiev.vm@gmail.com"]
  s.homepage = "http://github.com/palkan/influxer"
  s.summary = "InfluxDB for Rails"
  s.description = "InfluxDB the Rails way"
  s.license = "MIT"

  s.files = Dir.glob("lib/**/*") + %w[README.md LICENSE.txt CHANGELOG.md]
  s.require_paths = ["lib"]

  s.required_ruby_version = ">= 2.7.6"

  s.metadata = {
    "bug_tracker_uri" => "http://github.com/palkan/influxer/issues",
    "changelog_uri" => "https://github.com/palkan/influxer/blob/master/Changelog.md",
    "documentation_uri" => "http://github.com/palkan/influxer",
    "homepage_uri" => "http://github.com/palkan/influxer",
    "source_code_uri" => "http://github.com/palkan/influxer"
  }

  s.add_dependency "activemodel", ">= 6.0"
  s.add_dependency "influxdb", "~> 0.8"
  s.add_dependency "anyway_config", ">= 2.0"

  s.add_development_dependency "timecop"
  s.add_development_dependency "rake", "~> 10.1"
  s.add_development_dependency "rspec", ">= 3.1.0"
  s.add_development_dependency "standard", "~> 0.0.39"
  s.add_development_dependency "rubocop-md", "~> 0.2.0"
  s.add_development_dependency "webmock", "~> 2.1"
end
