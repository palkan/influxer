# frozen_string_literal: true

require "active_support/per_thread_registry"

module Influxer
  module Scoping
    module CurrentScope # :nodoc:
      # Clone of current_scope methods for newer versions of ActiveModel
      def current_scope
        ScopeRegistry.value_for(:current_scope, name)
      end

      def current_scope=(scope)
        ScopeRegistry.set_value_for(:current_scope, name, scope)
      end

      class ScopeRegistry # :nodoc:
        extend ActiveSupport::PerThreadRegistry

        VALID_SCOPE_TYPES = [:current_scope].freeze

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
          return if VALID_SCOPE_TYPES.include?(scope_type)

          raise ArgumentError, "Invalid scope type '#{scope_type}' sent to the registry. \
        Scope types  must be included in VALID_SCOPE_TYPES"
        end
      end
    end
  end
end
