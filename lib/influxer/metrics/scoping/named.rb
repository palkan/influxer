module Influxer
  module Scoping
    module Named
      extend ActiveSupport::Concern

      module ClassMethods
        def scope(name, scope)
          raise Error.new("Scope not defined: #{name}") if scope.nil? or !scope.respond_to?(:call)
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