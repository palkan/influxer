# frozen_string_literal: true

module Influxer
  module TimestampQuoting #:nodoc:
    TIME_FACTORS = {
      'ns' => 1_000_000_000,
      'ms' => 1_000,
      's' => 1
    }.freeze

    # Quote timestamp
    # rubocop: disable Metrics/MethodLength
    def quote_timestamp(val, client)
      return quote_timestamp_ns(val) if Influxer.config.time_duration_suffix_enabled

      if !TIME_FACTORS.keys.include?(client.time_precision) &&
         !val.is_a?(Numeric)
        warn(
          "Influxer doesn't automatically cast Time and String values " \
          "to '#{client.time_precision}' precision. " \
          "Please, convert to numeric value yourself"
        )
        return val
      end

      factor = TIME_FACTORS.fetch(client.time_precision)

      factorize_timestamp(val, factor)
    end
    # rubocop: enable Metrics/MethodLength

    def quote_timestamp_ns(val)
      "#{factorize_timestamp(val, TIME_FACTORS.fetch('ns'))}ns"
    end

    def factorize_timestamp(val, factor)
      case val
      when Numeric
        (val.to_f * factor).to_i
      when String
        (Time.parse(val).to_r * factor).to_i
      when Date, DateTime
        (val.to_time.to_r * factor).to_i
      when Time
        (val.to_r * factor).to_i
      end
    end
  end
end
