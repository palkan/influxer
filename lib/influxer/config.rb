require 'anyway'

module Influxer
  # Influxer configuration
  class Config < Anyway::Config
    config_name :influxdb

    attr_config database: 'db',
                host: 'localhost',
                port: 8086,
                username: 'root',
                password: 'root',
                use_ssl: false,
                async: true,
                cache: false,
                retry: false,
                time_precision: 's',
                initial_delay: 0.01,
                max_delay: 30,
                read_timeout: 30,
                write_timeout: 5

    def load
      super
      # we want pass @cache value as options to cache store, so we want it to be a Hash
      @cache = {}.with_indifferent_access if @cache == true
    end
  end
end
