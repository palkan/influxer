require 'influxdb'

module Influxer
  class Client < ::InfluxDB::Client
    def initialize
      super Influxer.config.database, Influxer.config.as_json.symbolize_keys!
    end

    def cached_query(sql)
      unless Influxer.config.cache == false
        if Rails.cache.exists?(sql)
          return Rails.cache.read(sql)
        end

        data = self.query(sql)
        Rails.cache.write(sql, data, Influxer.config.cache)
        data
      else
        self.query(sql)
      end
    end
  end
end