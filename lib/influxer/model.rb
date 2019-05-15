# frozen_string_literal: true

require "active_support"

module Influxer
  # Add `has_metrics` method to AR::Base
  module Model
    extend ActiveSupport::Concern

    module ClassMethods # :nodoc:
      def has_metrics(*args, **params)
        metrics_name = args.empty? ? "metrics" : args.first.to_s

        klass = params[:class_name].present? ? params[:class_name] : "#{self}Metrics"
        klass = klass.constantize

        attrs = params[:inherits] if params[:inherits].present?

        foreign_key = params.fetch(:foreign_key, to_s.foreign_key)

        define_method(metrics_name) do
          rel_attrs = foreign_key ? {foreign_key => id} : {}

          attrs&.each do |key|
            rel_attrs[key] = send(key)
          end
          Relation.new klass, attributes: rel_attrs
        end
      end
    end
  end
end
