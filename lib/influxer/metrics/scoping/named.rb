# frozen_string_literal: true

require "active_support/concern"

module Influxer
  module Scoping
    module Named # :nodoc: all
      extend ActiveSupport::Concern

      module ClassMethods
        def scope(name, scope)
          raise "Scope not defined: #{name}" if scope.nil? || !scope.respond_to?(:call)

          singleton_class.send(:define_method, name) do |*args|
            rel = all
            rel.merge!(rel.scoping { scope.call(*args) })
            rel
          end
        end
      end
    end
  end
end
