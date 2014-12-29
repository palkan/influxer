require 'active_support/per_thread_registry'
require 'influxer/metrics/scoping/default'
require 'influxer/metrics/scoping/named'

module Influxer
  module Scoping
    extend ActiveSupport::Concern

    class Error < StandardError; end;

    included do
      include Default
      include Named
    end

    module ClassMethods
      def current_scope #:nodoc:
        ScopeRegistry.value_for(:current_scope, name)
      end

      def current_scope=(scope) #:nodoc:
        ScopeRegistry.set_value_for(:current_scope, name, scope)
      end
    end

    class ScopeRegistry # :nodoc:
      extend ActiveSupport::PerThreadRegistry

      VALID_SCOPE_TYPES = [:current_scope]

      def initialize
        @registry = Hash.new { |hash, key| hash[key] = {} }
      end

      # Obtains the value for a given +scope_name+ and +variable_name+.
      def value_for(scope_type, variable_name)
        raise_invalid_scope_type!(scope_type)
        @registry[scope_type][variable_name]
      end

      # Sets the +value+ for a given +scope_type+ and +variable_name+.
      def set_value_for(scope_type, variable_name, value)
        raise_invalid_scope_type!(scope_type)
        @registry[scope_type][variable_name] = value
      end

      private

      def raise_invalid_scope_type!(scope_type)
        if !VALID_SCOPE_TYPES.include?(scope_type)
          raise ArgumentError, "Invalid scope type '#{scope_type}' sent to the registry. Scope types must be included in VALID_SCOPE_TYPES"
        end
      end
    end
  end
end