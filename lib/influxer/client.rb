# frozen_string_literal: true

require "influxdb"

module Influxer
  # InfluxDB API client
  class Client < ::InfluxDB::Client
    def initialize
      super(**Influxer.config.to_h.symbolize_keys)
    end

    def time_precision
      @config.time_precision
    end
  end
end
