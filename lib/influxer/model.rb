require 'active_support'

module Influxer
  module Model
    extend ActiveSupport::Concern
  
    module ClassMethods
      def has_metrics(*args, **params)
        p args
        p params
      end
    end
  end
end