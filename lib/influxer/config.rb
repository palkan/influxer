# frozen_string_literal: true

require "anyway_config"

module Influxer
  # Influxer configuration
  class Config < Anyway::Config
    config_name :influxdb

    # influxdb-ruby configuration parameters + cache option
    attr_config :hosts,
                :host,
                :port,
                :username,
                :password,
                :database,
                :time_precision,
                :use_ssl,
                :verify_ssl,
                :ssl_ca_cert,
                :auth_method,
                :initial_delay,
                :max_delay,
                :open_timeout,
                :read_timeout,
                :retry,
                :prefix,
                :denormalize,
                :udp,
                :async,
                :cache_enabled,
                :cache,
                database: "db",
                time_precision: "ns",
                time_duration_suffix_enabled: false

    def load(*)
      super
      if cache_enabled.nil?
        self.cache_enabled = cache_enabled_value
      end
    end

    def cache=(value)
      super
      self.cache_enabled = cache_enabled_value
    end

    private

    def cache_enabled_value
      !!cache
    end
  end
end
