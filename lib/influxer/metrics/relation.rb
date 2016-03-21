require 'influxer/metrics/relation/time_query'
require 'influxer/metrics/relation/calculations'
require 'influxer/metrics/relation/where_clause'

module Influxer
  # Relation is used to build queries
  # rubocop:disable Metrics/ClassLength
  class Relation
    include Influxer::TimeQuery
    include Influxer::Calculations
    include Influxer::WhereClause

    attr_reader :values

    MULTI_VALUE_METHODS = [:select, :where, :group, :order]

    MULTI_KEY_METHODS = [:fanout]

    SINGLE_VALUE_METHODS = [:fill, :time, :limit, :offset, :slimit, :soffset, :normalized]

    MULTI_VALUE_SIMPLE_METHODS = [:select, :group]

    SINGLE_VALUE_SIMPLE_METHODS = [:fill, :limit, :offset, :slimit, :soffset]

    MULTI_VALUE_METHODS.each do |name|
      class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}_values                          # def select_values
          @values[:#{name}] ||= []                  #   @values[:select] || []
        end                                         # end
      CODE
    end

    MULTI_KEY_METHODS.each do |name|
      class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}_values                          # def fanout_values
          @values[:#{name}] ||= {}                  #   @values[:fanout] || {}
        end                                         # end
      CODE
    end

    SINGLE_VALUE_METHODS.each do |name|
      class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}_value                           # def limit_value
          @values[:#{name}]                         #   @values[:limit]
        end                                         # end
      CODE
    end

    SINGLE_VALUE_SIMPLE_METHODS.each do |name|
      class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}(val)                            # def limit(val)
          @values[:#{name}] = val                   #   @value[:limit] = val
          self                                      #   self
        end                                         # end
      CODE
    end

    MULTI_VALUE_SIMPLE_METHODS.each do |name|
      class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}(*args)                          # def select(*args)
          #{name}_values.concat args.map(&:to_s)    #  select_values.concat args.map(&:to_s)
          self                                      #  self
        end                                         # end
      CODE
    end

    # delegate array methods to to_a
    delegate :to_xml, :to_yaml, :length, :collect, :map, :each, :all?, :include?, :to_ary, :join,
             to: :to_a

    # Initialize new Relation for 'klass' (Class) metrics.
    #
    # Available params:
    #  :attributes - hash of attributes to be included to new Metrics object
    #  and where clause of Relation
    #
    def initialize(klass, params = {})
      @klass = klass
      @instance = klass.new params[:attributes]
      reset
      where(params[:attributes]) if params[:attributes].present?
      self
    end

    def write(params = {})
      build(params).write
    end

    def write!(params = {})
      build(params).write!
    end

    def build(params = {})
      point = @instance.dup
      params.each do |key, val|
        point.send("#{key}=", val) if point.respond_to?(key)
      end
      point
    end

    alias_method :new, :build

    def normalized
      @values[:normalized] = true
      self
    end

    def normalized?
      @values[:normalized] == true
    end

    def order(val)
      case val
      when Hash
        val.each { |k, v| order_values << "#{k} #{v}" }
      when String
        order_values << val
      end
      self
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/PerceivedComplexity
    def to_sql
      sql = ["select"]
      select_values << "*" if select_values.empty?

      sql << select_values.uniq.join(",")

      sql << "from #{build_series_name}"

      sql << "where #{where_values.join(' and ')}" unless where_values.empty?

      unless group_values.empty? && time_value.nil?
        group_fields = (time_value.nil? ? [] : ['time(' + @values[:time] + ')']) + group_values
        group_fields.uniq!
        sql << "group by #{group_fields.join(',')}"
      end

      sql << "fill(#{fill_value})" unless fill_value.nil?

      sql << "order by #{order_values.uniq.join(',')}" unless order_values.empty?

      sql << "limit #{limit_value}" unless limit_value.nil?
      sql << "offset #{offset_value}" unless offset_value.nil?
      sql << "slimit #{slimit_value}" unless slimit_value.nil?
      sql << "soffset #{soffset_value}" unless soffset_value.nil?
      sql.join " "
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/PerceivedComplexity

    def to_a
      return @records if loaded?
      load
    end

    def inspect
      entries = to_a.take(11).map!(&:inspect)
      entries[10] = '...' if entries.size == 11

      "#<#{self.class.name} [#{entries.join(', ')}]>"
    end

    def empty?
      unless loaded?
        # we don't need selects here
        select_values.clear
        limit(1).load
      end
      @records.empty?
    end

    def as_json(options = nil)
      to_a.as_json(options)
    end

    def load
      @records = get_points(@instance.client.query(to_sql, denormalize: !normalized?))
      @loaded = true
      @records
    end

    def delete_all
      sql = ["drop series"]

      sql << "from #{@instance.series}"

      sql << "where #{where_values.join(' and ')}" unless where_values.empty?

      sql = sql.join " "

      @instance.client.query sql
    end

    def scoping
      previous, @klass.current_scope = @klass.current_scope, self
      yield
    ensure
      @klass.current_scope = previous
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def merge!(rel)
      return self if rel.nil?
      MULTI_VALUE_METHODS.each do |method|
        (@values[method] ||= []).concat(rel.values[method]).uniq! unless rel.values[method].nil?
      end

      MULTI_KEY_METHODS.each do |method|
        (@values[method] ||= {}).merge!(rel.values[method]) unless rel.values[method].nil?
      end

      SINGLE_VALUE_METHODS.each do |method|
        @values[method] = rel.values[method] unless rel.values[method].nil?
      end

      self
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength

    protected

    def build_series_name
      @instance.series
    end

    def loaded?
      @loaded
    end

    def reset
      @values = {}
      @records = nil
      @loaded = false
      self
    end

    def reload
      reset
      load
      self
    end

    def quoted(val, key = nil)
      if val.is_a?(String) || val.is_a?(Symbol) || @klass.tag?(key)
        "'#{val}'"
      elsif val.is_a?(Time) || val.is_a?(DateTime)
        "#{val.to_i}s"
      else
        val.to_s
      end
    end

    def get_points(list)
      return list if normalized?
      list.reduce([]) do |a, e|
        a + e.fetch("values", []).map { |v| inject_tags(v, e["tags"] || {}) }
      end
    end

    def inject_tags(val, tags)
      val.merge(tags)
    end

    def method_missing(method, *args, &block)
      return super unless @klass.respond_to?(method)
      merge!(scoping { @klass.public_send(method, *args, &block) })
    end
  end
end
