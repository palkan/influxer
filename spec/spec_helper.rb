$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

ENV["RAILS_ENV"] ||= 'test'

if ENV['COVER']
  require 'simplecov'
  SimpleCov.root File.join(File.dirname(__FILE__), '..')
  SimpleCov.start
end

require 'rspec'
require 'pry-byebug'
require 'timecop'

require 'active_record'
require 'sqlite3'

require "influxer"

# Rails stub
class Rails
  class << self
    def cache
      @cache ||= ActiveSupport::Cache::MemoryStore.new
    end

    def logger
      @logger ||= Logger.new(nil)
    end
  end
end

require "influxer/rails/client"

ActiveRecord::Base.send :include, Influxer::Model

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

Dir["#{File.dirname(__FILE__)}/support/metrics/*.rb"].each { |f| require f }
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec

  config.after(:each) { Influxer.reset! }
  config.after(:each) { Timecop.return }
end
