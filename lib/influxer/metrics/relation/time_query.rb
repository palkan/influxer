# frozen_string_literal: true

module Influxer
  module TimeQuery #:nodoc:
    TIME_ALIASES = {
      hour: "1h",
      minute: "1m",
      second: "1s",
      ms: "1ms",
      u: "1u",
      week: "1w",
      day: "1d",
      month: "30d",
      year: "365d"
    }.freeze

    FILL_RESERVED = %i[null previous none].freeze

    # Add group value to relation. To be used instead of `group("time(...)").
    # Accepts symbols and strings.
    #
    # You can set fill value within options.
    #
    #    Metrics.time(:hour)
    #    # select * from metrics group by time(1h)
    #
    #    Metrics.time("4d", fill: 0)
    #    # select * from metrics group by time(4d) fill(0)
    def time(val, options = {})
      @values[:time] = if val.is_a?(Symbol)
        TIME_ALIASES[val] || "1" + val.to_s
      else
        val
      end

      build_fill(options[:fill])
      self
    end

    # Shortcut to define time interval with regard to current time.
    # Accepts symbols and numbers.
    #
    #    Metrics.past(:hour)
    #    # select * from metrics where time > now() - 1h
    #
    #    Metrics.past(:d)
    #    # select * from metrics where time > now() - 1d
    #
    #    Metrics.past(2.days)
    #    # select * from metrics where time > now() - 172800s
    def past(val)
      case val
      when Symbol
        where("time > now() - #{TIME_ALIASES[val] || ("1" + val.to_s)}")
      when String
        where("time > now() - #{val}")
      else
        where("time > now() - #{val.to_i}s")
      end
    end

    # Shortcut to define start point of the time interval.
    # Accepts DateTime objects.
    #
    #    Metrics.since(1.day.ago) # assume that now is 2014-12-31 12:00:00 UTC
    #    # select * from metrics where time > 1420027200s
    #
    #    Metrics.since(Time.local(2014,12,31))
    #    # select * from metrics where time > 1419984000s

    def since(val)
      where("time > #{val.to_i}s")
    end

    private

    def build_fill(val)
      return if val.nil?

      fill(FILL_RESERVED.include?(val) ? val.to_s : val.to_i)
    end
  end
end
