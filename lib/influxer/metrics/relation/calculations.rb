module Influxer
  module Calculations
    CALCULATION_METHODS = 
      [
        :count, :min, :max, :mean, 
        :mode, :median, :distinct, :derivative, 
        :stddev, :sum, :first, :last, :difference,
        :percentile, :histogram, :top, :bottom
      ]

    CALCULATION_METHODS.each do |name|
      class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}(val, option=nil)                                                   # def count(val)
          @values[:has_calculations] = true                                            #   @values[:has_calculations] = true 
          select_values << "#{name}(\#\{val\}\#\{option ? ','+option.to_s : ''\})"     #   select_values << "count(\#\{val\})" 
          self                                                                         #   self
        end                                                                            # end
      CODE
    end
  end
end