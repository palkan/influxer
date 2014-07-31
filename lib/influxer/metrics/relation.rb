module Influxer
  class Relation
    
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

    # accepts strings and symbols only
    def select(*args)
      return self if args.empty?
      @select_values.concat args
      self
    end

    # accepts hash or strings conditions
    # TODO: add sanitization and array support

    def where(*args,**hargs)
      @where_values.concat args.map{|str| "(#{str})"}
      
      unless hargs.empty?
        hargs.each do |key, val|
          @where_values << "(#{key}=#{quoted(val)})"
        end
      end
      self
    end

    def group(*args)
      return self if args.empty?
      @group_values.concat args
      self
    end

    def limit(val)
      @limit = val
      self
    end

    def to_sql
      sql = ["select"]

      if @select_values.empty?
        sql << "*"
      else
        sql << @select_values.join(",")
      end 

      sql << "from #{@instance.series}"

      unless @group_values.empty?
        sql << "group by #{@group_values.join(",")}"
      end

      unless @where_values.empty?
        sql << "where #{@where_values.join(" and ")}"
      end

      unless @limit.nil?
        sql << "limit #{@limit}"
      end
      sql.join " "
    end

    def to_a
      return @records if loaded?
      load
      @records
    end

    def as_json
      to_a.as_json
    end

    def delete_all

    end

    protected
      def load
        @records = @instance.client.query to_sql
        @loaded = true
      end

      def loaded?
        @loaded
      end

      def reset
        @limit = nil
        @select_values = []
        @group_values = []
        @where_values = []
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