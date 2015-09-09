class UserMetrics < Influxer::Metrics
  tags :user_id
  attributes :time_spent
end
