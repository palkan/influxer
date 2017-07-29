# frozen_string_literal: true

class CustomMetrics < Influxer::Metrics
  tags :code, :user_id
  attributes :val
end
