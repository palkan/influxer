# frozen_string_literal: true

require "influxer/metrics/scoping/default"
require "influxer/metrics/scoping/named"

if Influxer.active_model3?
  require "influxer/metrics/scoping/old_current_scope"
else
  require "influxer/metrics/scoping/current_scope"
end

module Influxer
  # Clone of ActiveRecord::Relation scoping
  module Scoping # :nodoc:
    extend ActiveSupport::Concern

    class Error < StandardError; end

    included do
      include Default
      include Named
    end

    module ClassMethods # :nodoc:
      include Influxer::Scoping::CurrentScope
    end
  end
end
