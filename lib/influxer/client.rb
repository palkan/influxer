require 'influxdb'

module Influxer
  class Client < ::InfluxDB::Client
    def initialize
      super Influxer.config.database, Influxer.config.as_json.symbolize_keys!
    end

    def cached_query(sql)
      unless Influxer.config.cache == false
        if Rails.cache.exist?(sql)
          return Rails.cache.read(sql)
        end

        data = self.query(sql)
        Rails.cache.write(sql, data, cache_options(sql))
        data
      else
        self.query(sql)
      end
    end
  end


  private
    def cache_options(sql=nil)
      options = Influxer.config.cache.dup
      # if sql contains 'now()' set expires to 1 minute or :cache_now_for value of config.cache if defined
      if sql =~ /\snow\(\)/
        options[:expires_in] = options[:cache_now_for] || 60
      end
      options
    end
end