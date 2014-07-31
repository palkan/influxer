module Influxer
  class MetricsError < StandardError; end
  class MetricsInvalid < MetricsError; end
  
  class Metrics
    include ActiveModel::Model
    include ActiveModel::Validations
    extend ActiveModel::Callbacks

    define_model_callbacks :write

    class << self
      delegate :select, :where, :group, :limit, :delete_all, to: :all

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

      def inherited(subclass)
        subclass.set_series
      end
    
      def set_series(*args)
        if args.empty?
          matches = self.to_s.match(/^(.*)Metrics$/)
          if matches.nil?
            @series = self.to_s.underscore
          else
            @series = matches[1].split("::").join("_").underscore
          end
        elsif args.first.is_a?(Proc)
          @series = args.first
        else
          @series = args.join(",")
        end
      end

      def series
        @series
      end

      def all
        Relation.new self
      end
    end

    def initialize(attributes = {})
      @attributes = {}
      @persisted = false
      super
    end

    def write
      raise MetricsError.new('Cannot write the same metrics twice') if self.persisted?

      return false if self.invalid?

      run_callbacks :write do
        self.write_point
      end
    end

    def write!
      raise MetricsInvalid.new('Validation failed') if self.invalid?
      self.write
    end

    def write_point
      client.write_point series, @attributes
      @persisted = true
    end 

    def persisted?
      @persisted
    end

    def series
      self.class.series.is_a?(Proc) ? self.class.series.call(self) : self.class.series
    end

    def client
      Influxer.client
    end

    attributes :time
  end
end 