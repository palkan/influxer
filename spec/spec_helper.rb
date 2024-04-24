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

# In rails 7 add own deprecation object
# https://github.com/rails/rails/commit/e5af9c298a108469a43758297ab56d12b3f0ddcf#diff-c92225c96a8ba2fd9443834863f5f164d55c4847331168a5f9a00d2fe7923aae
if ActiveModel::VERSION::MAJOR < 7
  ActiveSupport::Deprecation.behavior = :raise
end

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
