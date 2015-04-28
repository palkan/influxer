module Influxer
  module FanoutQuery #:nodoc:
    # Instance methods are included to Relation
    def build_fanout(key, val)
      @values[:has_fanout] = true
      if val.is_a?(Regexp)
        @values[:fanout_rxp] = true
        fanout_values[key.to_s] = val.inspect[1..-2]
      else
        fanout_values[key.to_s] = val.to_s
      end
    end

    def build_series_name
      if @values[:has_fanout] == true
        fan_parts = [@instance.series[1..-2]]
        @klass.fanouts.each do |name|
          if fanout_values.key?(name)
            fan_parts << name
            fan_parts << fanout_values[name]
          end
        end
        if @values[:fanout_rxp] == true
          "/^#{ fan_parts.join(@klass.fanout_options[:delimeter]) }$/"
        else
          @klass.quoted_series(fan_parts.join(@klass.fanout_options[:delimeter]))
        end
      else
        @instance.series
      end
    end

    def prepare_fanout_points(hash)
      hash.each do |k, v|
        data = extract_values(k)
        v.each { |p| p.merge!(data) } unless data.empty?
      end
      hash
    end

    private

    # Extract fanout values from series name
    def extract_values(name)
      data = @klass.fanout_rxp.match(name)
      Hash[data.names.zip(data.captures)].compact
    end
  end
end
