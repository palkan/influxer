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
                database: "db",
                time_precision: "ns",
                cache: {}.with_indifferent_access,
                time_duration_suffix_enabled: false

    def load(*)
      super
      # we want pass @cache value as options to cache store, so we want it to be a Hash
      self.cache_enabled = false if cache.blank? || cache_enabled == false
    end
  end
end
