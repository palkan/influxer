require 'influxer/metrics/relation'
require 'influxer/metrics/scoping'
require 'influxer/metrics/fanout'
require 'active_model'

module Influxer
  class MetricsError < StandardError; end
  class MetricsInvalid < MetricsError; end

  # Base class for InfluxDB querying and writing
  class Metrics
    include ActiveModel::Model
    include ActiveModel::Validations
    extend ActiveModel::Callbacks

    include Influxer::Scoping
    include Influxer::Fanout

    define_model_callbacks :write

    class << self
      # delegate query functions to all
      delegate(
        *(
          [
            :write, :select, :where, :group,
            :merge, :time, :past, :since, :limit,
            :fill, :delete_all
          ] + Influxer::Calculations::CALCULATION_METHODS
        ),
        to: :all
      )

      attr_reader :series

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
          matches = to_s.match(/^(.*)Metrics$/)
          if matches.nil?
            @series = superclass.respond_to?(:series) ? superclass.series : to_s.underscore
          else
            @series = matches[1].split("::").join("_").underscore
          end
        elsif args.first.is_a?(Proc)
          @series = args.first
        else
          @series = args
        end
      end

      def all
        if current_scope
          current_scope.clone
        else
          default_scoped
        end
      end

      def quoted_series(val = @series, instance = nil)
        case val
        when Regexp
          val.inspect
        when Proc
          quoted_series(val.call(instance))
        when Array
          if val.length > 1
            "merge(#{ val.map { |s| quoted_series(s) }.join(',') })"
          else
            quoted_series(val.first)
          end
        else
          '"' + val.to_s.gsub(/\"/) { %q(\") } + '"'
        end
      end
    end

    def initialize(attributes = {})
      @attributes = {}
      @persisted = false
      super
    end

    def write
      fail MetricsError if self.persisted?

      return false if self.invalid?

      run_callbacks :write do
        write_point
      end
      self
    end

    def write!
      fail MetricsInvalid if self.invalid?
      write
    end

    def write_point
      client.write_point unquote(series), @attributes
      @persisted = true
    end

    def persisted?
      @persisted
    end

    def series
      self.class.quoted_series(self.class.series, self)
    end

    def client
      Influxer.client
    end

    attributes :time

    private

    def unquote(name)
      name.gsub(/(\A['"]|['"]\z)/, '')
    end
  end
end
