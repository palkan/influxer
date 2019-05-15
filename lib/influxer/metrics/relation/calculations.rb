# frozen_string_literal: true

module Influxer
  module Calculations #:nodoc:
    CALCULATION_METHODS =
      [
        :count, :min, :max, :mean,
        :mode, :median, :distinct, :derivative,
        :stddev, :sum, :first, :last
      ].freeze

    CALCULATION_METHODS.each do |name|
      class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}(val, alias_name = nil)                                                        # def count(val)
          @values[:has_calculations] = true                                                       #   @values[:has_calculations] = true
          select_values << "#{name}(\#\{val\})\#\{alias_name ? ' as '+alias_name.to_s : ''\}"     #   select_values << "count(\#\{val\})"
          self                                                                                    #   self
        end                                                                                       # end
      CODE
    end

    def percentile(name, val, alias_name = nil)
      @values[:has_calculations] = true
      select_values << "percentile(#{name}, #{val})#{alias_name ? " as " + alias_name.to_s : ""}"
      self
    end
  end
end
