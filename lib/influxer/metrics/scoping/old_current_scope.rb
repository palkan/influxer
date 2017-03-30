module Influxer
  module Scoping
    # Clone of current_scope methods for older versions of ActiveModel
    module CurrentScope
      def current_scope
        Thread.current["#{self}_current_scope"]
      end

      def current_scope=(scope)
        Thread.current["#{self}_current_scope"] = scope
      end
    end
  end
end
