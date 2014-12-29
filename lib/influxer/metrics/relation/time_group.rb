module Influxer
  module TimeGroup
    TIME_ALIASES = {
      hour: '1h',
      minute: '1m',
      second: '1s',
      ms: '1u',
      week: '1w',
      day: '1d',
      month: '30d'        
    }

    def time(val, options={})
      if val.is_a?(Symbol)
        group("time(#{ TIME_ALIASES[val] || ('1'+val.to_s)  })")
      else
        group("time(#{val})")
      end

      unless options[:fill].nil?
        @fill_value = (options[:fill] == :null) ? 'null' : options[:fill].to_i
      end
      self
    end
  end
end