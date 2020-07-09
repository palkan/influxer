# frozen_string_literal: true

require "influxer/metrics/relation"
require "influxer/metrics/scoping"
require "influxer/metrics/quoting/timestamp"
require "influxer/metrics/active_model3/model"

module Influxer
  class MetricsError < StandardError; end
  class MetricsInvalid < MetricsError; end

  # Base class for InfluxDB querying and writing
  class Metrics
    TIME_FACTOR = 1_000_000_000
    if Influxer.active_model3?
      include Influxer::ActiveModel3::Model
    else
      include ActiveModel::Model
    end

    include ActiveModel::Validations
    extend ActiveModel::Callbacks

    include Influxer::Scoping
    include Influxer::TimestampQuoting

    define_model_callbacks :write

    class << self
      # delegate query functions to all
      delegate(
        *(
          [
            :write, :write!, :select, :where,
            :group, :time, :past, :since,
            :limit, :offset, :fill, :delete_all, :epoch, :timezone
          ] + Influxer::Calculations::CALCULATION_METHODS
        ),
        to: :all
      )

      attr_reader :series, :retention_policy, :database, :precision
      attr_accessor :tag_names

      def attributes(*attrs)
        attrs.each do |name|
          define_method("#{name}=") do |val|
            @attributes[name] = val
          end

          define_method(name.to_s) do
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

      # Use custom retention policy
      def set_retention_policy(policy_name)
        @retention_policy = policy_name
      end

      # Use custom database for this metrics
      def set_database(database)
        @database = database
      end

      # Use custom precision for this metrics
      def set_precision(precision)
        @precision = precision
      end

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize
      def set_series(*args)
        if args.empty?
          matches = to_s.match(/^(.*)Metrics$/)
          @series =
            if matches.nil?
              superclass.respond_to?(:series) ? superclass.series : to_s.underscore
            else
              matches[1].split("::").join("_").underscore
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
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/CyclomaticComplexity
      def quoted_series(val = @series, instance = nil, write: false)
        case val
        when Regexp
          val.inspect
        when Proc
          quoted_series(val.call(instance), write: write)
        when Array
          if val.length > 1
            "merge(#{val.map { |s| quoted_series(s, write: write) }.join(",")})"
          else
            quoted_series(val.first, write: write)
          end
        else
          # Only add retention policy when selecting points
          # and not writing
          if !write && retention_policy.present?
            [quote(@retention_policy), quote(val)].join(".")
          else
            quote(val)
          end
        end
      end

      def quote(name)
        '"' + name.to_s.gsub(/\"/) { '\"' } + '"'
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength
    end

    attr_accessor :timestamp

    def initialize(attributes = {})
      @attributes = {}
      @persisted = false
      super
    end

    def write
      raise MetricsError if persisted?

      return false if invalid?

      run_callbacks :write do
        write_point
      end
      self
    end

    def write!
      raise MetricsInvalid if invalid?

      write
    end

    def write_point
      data = {
        values: values,
        tags: tags,
        timestamp: parsed_timestamp
      }
      write_with_config(
        unquote(series(write: true)),
        data
      )
      @persisted = true
    end

    def persisted?
      @persisted
    end

    def series(**options)
      self.class.quoted_series(self.class.series, self, **options)
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

    def tag_names
      self.class.tag_names
    end

    private

    def write_with_config(series, data)
      client.write_point(series, data,
                         self.class.precision,
                         self.class.retention_policy,
                         self.class.database)
    end

    def parsed_timestamp
      quote_timestamp_for_write @timestamp, client
    end

    def unquote(name)
      name.gsub(/(\A['"]|['"]\z)/, "")
    end
  end
end
