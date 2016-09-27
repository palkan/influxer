module Influxer
  module WhereClause #:nodoc:
    # accepts hash or strings conditions
    def where(*args, **hargs)
      build_where(args, hargs, false)
      self
    end

    def not(*args, **hargs)
      build_where(args, hargs, true)
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
        where_values << "(#{build_eql(key, val, negate)})"
      end
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/MethodLength
    def build_eql(key, val, negate)
      case val
      when NilClass
        build_eql(key, /.*/, !negate)
      when Regexp
        "#{key}#{negate ? ' !~ ' : ' =~ '}#{val.inspect}"
      when Array
        build_in(key, val, negate)
      when Range
        build_range(key, val, negate)
      else
        "#{key}#{negate ? ' <> ' : ' = '}#{quoted(val, key)}"
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/MethodLength

    def build_in(key, arr, negate)
      buf = []
      arr.each do |val|
        buf << build_eql(key, val, negate)
      end
      buf.join(negate ? ' and ' : ' or ').to_s
    end

    def build_range(key, val, negate)
      if negate
        "#{key} < #{quoted(val.begin)} or #{key} > #{quoted(val.end)}"
      else
        "#{key} > #{quoted(val.begin)} and #{key} < #{quoted(val.end)}"
      end
    end
  end
end
