require 'anyway'

module Influxer
  class Config < Anyway::Config
    config_name :influxdb

    attr_config database: 'db', 
                host: 'localhost',
                port: 8083,
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
      if @cache == true
        @cache = {}.with_indifferent_access
      end
    end
  end
end