# frozen_string_literal: true

require "influxer"

module Influxer
  class Engine < Rails::Engine # :nodoc:
    initializer "extend ActiveRecord with influxer" do |_app|
      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Base.send :include, Influxer::Model
      end
    end

    initializer "set InfluxDB logger" do |_app|
      InfluxDB::Logging.logger = Rails.logger
    end
  end
end
