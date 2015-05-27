require 'influxer/metrics/relation/time_query'
require 'influxer/metrics/relation/fanout_query'
require 'influxer/metrics/relation/calculations'

module Influxer
  # Relation is used to build queries
  class Relation
    include Influxer::TimeQuery
    include Influxer::FanoutQuery
    include Influxer::Calculations

    attr_reader :values

    MULTI_VALUE_METHODS = [:select, :where, :group]

    MULTI_KEY_METHODS = [:fanout]

    SINGLE_VALUE_METHODS = [:fill, :limit, :merge, :time]

    MULTI_VALUE_SIMPLE_METHODS = [:select, :group]

    SINGLE_VALUE_SIMPLE_METHODS = [:fill, :limit, :merge]

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

    # accepts hash or strings conditions
    def where(*args, **hargs)
      build_where(args, hargs, false)
      self
    end

    def not(*args, **hargs)
      build_where(args, hargs, true)
      self
    end

    def to_sql
      sql = ["select"]
      select_values << "*" if select_values.empty?

      sql << select_values.uniq.join(",")

      sql << "from #{ build_series_name }"
      sql << "merge #{ @klass.quoted_series(merge_value) }" unless merge_value.nil?

      unless group_values.empty? && time_value.nil?
        group_fields = (time_value.nil? ? [] : ['time(' + @values[:time] + ')']) + group_values
        group_fields.uniq!
        sql << "group by #{ group_fields.join(',') }"
      end

      sql << "fill(#{ fill_value })" unless fill_value.nil?

      sql << "where #{ where_values.join(' and ') }" unless where_values.empty?

      sql << "limit #{ limit_value }" unless limit_value.nil?
      sql.join " "
    end

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
      @records = get_points(@instance.client.cached_query(to_sql))
      @loaded = true
      @records
    end

    def delete_all
      sql = ["delete"]

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

    protected

    def build_where(args, hargs, negate)
      case
      when (args.present? && args[0].is_a?(String))
        where_values.concat args.map { |str| "(#{str})" }
      when hargs.present?
        build_hash_where(hargs, negate)
      else
        false
      end
    end

    def build_hash_where(hargs, negate = false)
      hargs.each do |key, val|
        if @klass.fanout?(key)
          build_fanout(key, val)
        else
          where_values << "(#{ build_eql(key, val, negate) })"
        end
      end
    end

    def build_eql(key, val, negate)
      case val
      when Regexp
        "#{key}#{ negate ? '!~' : '=~'}#{val.inspect}"
      when Array
        build_in(key, val, negate)
      when Range
        build_range(key, val, negate)
      else
        "#{key}#{ negate ? '<>' : '='}#{quoted(val)}"
      end
    end

    def build_in(key, arr, negate)
      buf = []
      arr.each do |val|
        buf << build_eql(key, val, negate)
      end
      "#{ buf.join(negate ? ' and ' : ' or ') }"
    end

    def build_range(key, val, negate)
      if negate
        "#{key}<#{quoted(val.begin)} and #{key}>#{quoted(val.end)}"
      else
        "#{key}>#{quoted(val.begin)} and #{key}<#{quoted(val.end)}"
      end
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

    def quoted(val)
      if val.is_a?(String) || val.is_a?(Symbol)
        "'#{val}'"
      elsif val.is_a?(Time) || val.is_a?(DateTime)
        "#{val.to_i}s"
      else
        val.to_s
      end
    end

    def get_points(hash)
      prepare_fanout_points(hash) if @values[:has_fanout] == true
      hash.values.reduce([], :+)
    end

    def method_missing(method, *args, &block)
      return super unless @klass.respond_to?(method)
      merge!(scoping { @klass.public_send(method, *args, &block) })
    end
  end
end
