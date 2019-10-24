# frozen_string_literal: true

module Influxer
  module TimestampQuoting #:nodoc:
    TIME_FACTORS = {
      "ns" => 1_000_000_000,
      "ms" => 1_000,
      "s" => 1
    }.freeze

    DEFAULT_PRECISION = "ns"

    # Quote timestamp
    # rubocop: disable Metrics/MethodLength, Metrics/AbcSize
    def quote_timestamp(val, client)
      if Influxer.config.time_duration_suffix_enabled
        precision = if TIME_FACTORS.key?(client.time_precision)
          client.time_precision
        else
          DEFAULT_PRECISION
        end
        return quote_timestamp_with_suffix(val, precision)
      end

      if !TIME_FACTORS.key?(client.time_precision) &&
          !val.is_a?(Numeric)
        warn(
          "Influxer doesn't automatically cast Time and String values " \
          "to '#{client.time_precision}' precision. " \
          "Please, convert to numeric value yourself"
        )
        return val
      end

      factorize_timestamp(val, TIME_FACTORS.fetch(client.time_precision))
    end
    # rubocop: enable Metrics/MethodLength, Metrics/AbcSize

    def quote_timestamp_with_suffix(val, precision)
      "#{factorize_timestamp(val, TIME_FACTORS.fetch(precision))}#{precision}"
    end

    def quote_timestamp_for_write(val, client)
      if !TIME_FACTORS.key?(client.time_precision) &&
          !val.is_a?(Numeric)
        raise ArgumentError,
              "Influxer doesn't support quoting #{val} " \
              " with '#{client.time_precision}' precision. " \
              "Please, convert to numeric value yourself"
      end

      factorize_timestamp(val, TIME_FACTORS.fetch(client.time_precision))
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
