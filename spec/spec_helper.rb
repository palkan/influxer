$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

ENV["RAILS_ENV"] ||= 'test'

if ENV['COVER']
  require 'simplecov'
  SimpleCov.root File.join(File.dirname(__FILE__), '..')
  SimpleCov.start
end

require 'rspec'
require 'pry'
require 'rails/all'
require 'rspec/rails'
require 'timecop'

require "dummy/config/environment"

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec
  config.use_transactional_fixtures = true
end
