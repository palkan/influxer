require 'active_support'

module Influxer
  module Model
    extend ActiveSupport::Concern
  
    module ClassMethods
      def has_metrics(*args, **params)
        metrics_name = args.empty? ? "metrics" : args.first.to_s

        klass = params[:class_name].present? ? params[:class_name] : "#{self}Metrics" 
        klass = klass.constantize

        attrs = nil

        if params[:inherits].present? 
          attrs = params[:inherits]
        end

        _foreign_key = params.key?(:foreign_key) ? params[:foreign_key] : self.to_s.foreign_key

        define_method(metrics_name) do
          rel_attrs = _foreign_key ? {_foreign_key => self.id} : {}
          
          unless attrs.nil?
            attrs.each do |key|
              rel_attrs[key] = self.send(key)
            end 
          end
          Relation.new klass, attributes: rel_attrs
        end
      end
    end
  end
end