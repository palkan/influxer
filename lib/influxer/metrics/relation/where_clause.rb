# frozen_string_literal: true

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

    def none
      where_values << "(#{build_none})"
      self
    end

    def loaded?
      @null_relation || super
    end

    def reset
      super
      @null_relation = false
    end

    def load
      return if @null_relation

      super
    end

    protected

    def build_where(args, hargs, negate)
      if args.present? && args[0].is_a?(String)
        where_values.concat(args.map { |str| "(#{str})" })
      elsif hargs.present?
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
        "#{key}#{negate ? " !~ " : " =~ "}#{val.inspect}"
      when Array
        return build_none(negate) if val.empty?

        build_in(key, val, negate)
      when Range
        build_range(key, val, negate)
      else
        "#{key}#{negate ? " <> " : " = "}#{quoted(val, key)}"
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/MethodLength

    def build_in(key, arr, negate)
      buf = []
      arr.each do |val|
        buf << build_eql(key, val, negate)
      end
      buf.join(negate ? " and " : " or ").to_s
    end

    # rubocop: disable Metrics/AbcSize, Metrics/MethodLength, Style/IfInsideElse
    def build_range(key, val, negate)
      if val.exclude_end?
        # begin...end range
        if negate
          "#{key} < #{quoted(val.begin, key)} or #{key} >= #{quoted(val.end, key)}"
        else
          "#{key} >= #{quoted(val.begin, key)} and #{key} < #{quoted(val.end, key)}"
        end
      else
        # begin..end range
        if negate
          "#{key} < #{quoted(val.begin, key)} or #{key} > #{quoted(val.end, key)}"
        else
          "#{key} >= #{quoted(val.begin, key)} and #{key} <= #{quoted(val.end, key)}"
        end
      end
    end
    # rubocop: enable Metrics/AbcSize, Metrics/MethodLength, Style/IfInsideElse

    def build_none(negate = false)
      @null_relation = !negate
      negate ? "time >= 0" : "time < 0"
    end

    def where_contains_time?
      where_values.any? do |where_clause|
        /time( )/ === where_clause
      end
    end
  end
end
