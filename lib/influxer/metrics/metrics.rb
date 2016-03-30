require 'influxer/metrics/relation'
require 'influxer/metrics/scoping'
require 'active_model'

module Influxer
  class MetricsError < StandardError; end
  class MetricsInvalid < MetricsError; end

  # Base class for InfluxDB querying and writing
  # rubocop:disable Metrics/ClassLength
  class Metrics
    TIME_FACTOR = 1_000_000_000
    include ActiveModel::Model
    include ActiveModel::Validations
    extend ActiveModel::Callbacks

    include Influxer::Scoping

    define_model_callbacks :write

    class << self
      # delegate query functions to all
      delegate(
        *(
          [
            :write, :write!, :select, :where,
            :group, :time, :past, :since,
            :limit, :offset, :fill, :delete_all, :epoch
          ] + Influxer::Calculations::CALCULATION_METHODS
        ),
        to: :all
      )

      attr_reader :series
      attr_accessor :tag_names

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

      def tags(*attrs)
        attributes(*attrs)
        self.tag_names ||= []
        self.tag_names += attrs.map(&:to_s)
      end

      def tag?(name)
        tag_names.include?(name.to_s)
      end

      def inherited(subclass)
        subclass.set_series
        subclass.tag_names = tag_names.nil? ? [] : tag_names.dup
      end

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize
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
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize

      def all
        if current_scope
          current_scope.clone
        else
          default_scoped
        end
      end

      # rubocop:disable Metrics/MethodLength
      def quoted_series(val = @series, instance = nil)
        case val
        when Regexp
          val.inspect
        when Proc
          quoted_series(val.call(instance))
        when Array
          if val.length > 1
            "merge(#{val.map { |s| quoted_series(s) }.join(',')})"
          else
            quoted_series(val.first)
          end
        else
          '"' + val.to_s.gsub(/\"/) { %q(\") } + '"'
        end
      end
      # rubocop:enable Metrics/MethodLength
    end

    delegate :tag_names, to: :class
    attr_accessor :timestamp

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
      client.write_point unquote(series), values: values, tags: tags, timestamp: parsed_timestamp
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

    def dup
      self.class.new(@attributes)
    end

    # Returns hash with metrics values
    def values
      @attributes.reject { |k, _| tag_names.include?(k.to_s) }
    end

    # Returns hash with metrics tags
    def tags
      @attributes.select { |k, _| tag_names.include?(k.to_s) }
    end

    private

    def parsed_timestamp
      return @timestamp unless client.time_precision == 'ns'

      case @timestamp
      when Numeric
        @timestamp.to_i.to_s.ljust(19, '0').to_i
      when String
        (Time.parse(@timestamp).to_r * TIME_FACTOR).to_i
      when Date
        (@timestamp.to_time.to_r * TIME_FACTOR).to_i
      when Time
        (@timestamp.to_r * TIME_FACTOR).to_i
      end
    end

    def unquote(name)
      name.gsub(/(\A['"]|['"]\z)/, '')
    end
  end
end
