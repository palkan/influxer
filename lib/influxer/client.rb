require 'influxdb'

module Influxer
  class Client < ::InfluxDB::Client
    def initialize
      super Influxer.config.database, Influxer.config.as_json.symbolize_keys!
    end
  end
end