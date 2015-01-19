require 'influxdb'

module Influxer
  class Client < ::InfluxDB::Client
    def initialize
      @instrumenter = ActiveSupport::Notifications.instrumenter
      super Influxer.config.database, Influxer.config.as_json.symbolize_keys!
    end

    def cached_query(sql)
      log(sql) do
        unless Influxer.config.cache == false
          Rails.cache.fetch(normalized_cache_key(sql), cache_options(sql)) { self.query(sql) }
        else
          self.query(sql)
        end
      end
    end
    
    private
      def log(sql, name = "InfluxDB SQL")
        @instrumenter.instrument(
          "sql.influxdb",
          :sql            => sql,
          :name           => name
        ) { yield }
      end

      def cache_options(sql=nil)
        options = Influxer.config.cache.dup
        # if sql contains 'now()' set expires to 1 minute or :cache_now_for value of config.cache if defined
        if sql =~ /\snow\(\)/
          options[:expires_in] = options[:cache_now_for] || 60
        end
        options
      end

      # add prefix; remove whitespaces
      def normalized_cache_key(sql)
        "influxer:#{sql.gsub(/\s*/, '')}"
      end
  end
end