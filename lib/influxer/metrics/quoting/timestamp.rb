# frozen_string_literal: true

module Influxer
  module TimestampQuoting #:nodoc:
    TIME_FACTOR = 1_000_000_000

    # Quote timestamp as ns
    # rubocop: disable Metrics/AbcSize, Metrics/MethodLength
    def quote_timestamp(val, client)
      return val unless client.time_precision == 'ns'

      case val
      when Numeric
        val.to_i.to_s.ljust(19, '0').to_i
      when String
        (Time.parse(val).to_r * TIME_FACTOR).to_i
      when Date, DateTime
        (val.to_time.to_r * TIME_FACTOR).to_i
      when Time
        (val.to_r * TIME_FACTOR).to_i
      end
    end
    # rubocop: enable Metrics/AbcSize, Metrics/MethodLength
  end
end
