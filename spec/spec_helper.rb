# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
$LOAD_PATH.unshift(File.dirname(__FILE__))

ENV["RAILS_ENV"] ||= "test"

require "rspec"
require "webmock/rspec"

begin
  require "pry-byebug"
rescue LoadError # rubocop:disable Lint/HandleExceptions
end

require "timecop"

require "active_record"
require "sqlite3"

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

    def env
      "test"
    end
  end
end

require "influxer/rails/client"

ActiveRecord::Base.send :include, Influxer::Model

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

Dir["#{File.dirname(__FILE__)}/support/metrics/*.rb"].sort.each { |f| require f }
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }

WebMock.disable_net_connect!

RSpec.configure do |config|
  config.mock_with :rspec

  config.example_status_persistence_file_path = "tmp/rspec_examples.txt"
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.order = :random
  Kernel.srand config.seed

  config.after(:each) { Influxer.reset! }
  config.after(:each) { Timecop.return }
end
