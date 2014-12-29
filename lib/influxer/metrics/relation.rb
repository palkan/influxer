module Influxer
  class Relation
    include Influxer::TimeQuery
    
    MULTI_VALUE_METHODS = [:select, :merge, :group, :where]

    MULTI_VALUE_SIMPLE_METHODS = [:select, :merge, :group]

    # Initialize new Relation for 'klass' (Class) metrics.
    # 
    # Available params:
    #  :attributes - hash of attributes to be included to new Metrics object and where clause of Relation
    # 
    def initialize(klass, params = {})
      @instance = klass.new params[:attributes]
      self.reset
      self.where(params[:attributes]) if params[:attributes].present?
      self
    end


    def write(params = {})
      build params
      @instance.write
    end

    def build(params = {})
      params.each do |key,val|
        @instance.send("#{key}=", val) if @instance.respond_to?(key)
      end
      @instance
    end

    MULTI_VALUE_METHODS.each do |name|
      class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}_values                   # def select_values
          @values[:#{name}] ||= []            #   @values[:select] || []
        end                                  # end
      CODE
    end

    MULTI_VALUE_SIMPLE_METHODS.each do |name|
      class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}(*args)                   # def select(*args)
          #{name}_values.concat args         #  select_values.concat args
          self                               #  self
        end                                  # end
      CODE
    end

    # accepts hash or strings conditions
    def where(*args,**hargs)
      build_where(args, hargs, false)
      self
    end

    def not(*args, **hargs)
      build_where(args, hargs, true)
      self
    end

    def limit(val)
      @values[:limit] = val
      self
    end

    def to_sql
      sql = ["select"]

      if select_values.empty?
        sql << "*"
      else
        sql << select_values.join(",")
      end 

      sql << "from #{@instance.series}"

      unless merge_values.empty?
        sql << "merge #{@instance.quote_series(merge_values.first)}"
      end

      unless group_values.empty?
        sql << "group by #{group_values.join(",")}"
      end

      unless @values[:fill].nil?
        sql << "fill(#{@values[:fill]})"
      end

      unless where_values.empty?
        sql << "where #{where_values.join(" and ")}"
      end

      unless @values[:limit].nil?
        sql << "limit #{@values[:limit]}"
      end
      sql.join " "
    end

    def to_a
      return @records if loaded?
      load
      @records
    end

    def inspect
      entries = to_a.take(11).map!(&:inspect)
      entries[10] = '...' if entries.size == 11

      "#<#{self.class.name} [#{entries.join(', ')}]>"
    end

    def as_json
      to_a.as_json
    end

    def delete_all
      sql = ["delete"]

      sql << "from #{@instance.series}"

      unless where_values.empty?
        sql << "where #{where_values.join(" and ")}"
      end

      sql = sql.join " "

      @instance.client.query sql
    end

    protected
      def build_where(args, hargs, negate)
        case
        when (args.present? and args[0].is_a?(String))
          where_values.concat args.map{|str| "(#{str})"}
        when hargs.present?
          build_hash_where(hargs, negate)
        else
          false
        end
      end

      def build_hash_where(hargs, negate = false)
        hargs.each do |key, val|
          where_values << "(#{ build_eql(key,val,negate) })"
        end
      end

      def build_eql(key,val,negate)
        case val
        when Regexp
          "#{key}#{ negate ? '!~' : '=~'}#{val.inspect}"
        when Array
          build_in(key,val,negate)
        when Range
          build_range(key,val,negate)
        else
          "#{key}#{ negate ? '<>' : '='}#{quoted(val)}"
        end  
      end

      def build_in(key, arr, negate)
        buf = []
        arr.each do |val|
          buf << build_eql(key,val,negate)
        end
        "#{ buf.join( negate ? ' and ' : ' or ') }"
      end

      def build_range(key,val,negate)
        unless negate
          "#{key}>#{quoted(val.begin)} and #{key}<#{quoted(val.end)}"
        else
          "#{key}<#{quoted(val.begin)} and #{key}>#{quoted(val.end)}"
        end  
      end

      def load
        @records = @instance.client.cached_query to_sql
        @loaded = true
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
        self.reset
        self.load
        self
      end

      def quoted(val)
        if val.is_a?(String)
          "'#{val}'"
        elsif val.kind_of?(Time) or val.kind_of?(DateTime)
          "#{val.to_i}s"
        else
          val.to_s
        end
      end
  end
end 