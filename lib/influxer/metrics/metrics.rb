module Influxer
  class Metrics
    include ActiveModel::Model
    include ActiveModel::Validations
    extend ActiveModel::Callbacks

    define_model_callbacks :write

    class << self
      @before_write = []

      def attributes(*attrs)
        attrs.each do |name|
          define_method("#{name}=") do |val|
            @attributes[name] = val
          end

          define_method("#{name}") do
            @attributes[name]
          end
        end
      end
    end

    attributes :time

    def initialize(attributes = {})
      @attributes = {}
      @persisted = false
      super
    end

    def write
      raise ::StandardError.new('Cannot write the same metrics twice') if self.persisted?

      return false if self.invalid?

      run_callbacks :write do
        self.write_point
      end
    end

    def write!
      raise ::StandardError.new('Validation failed') if self.invalid?
      self.write
    end

    def write_point
      @persisted = true
    end 

    def persisted?
      @persisted
    end
  end
end 