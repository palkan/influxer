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
                database: "db",
                time_precision: "ns",
                cache: false,
                time_duration_suffix_enabled: false

    def load(*)
      super
      # we want pass @cache value as options to cache store, so we want it to be a Hash
      @cache = {}.with_indifferent_access if @cache == true
    end
  end
end
