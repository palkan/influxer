class VisitsMetrics < Influxer::Metrics
  set_retention_policy :yearly

  tags :user_id, :gender
  attributes :age, :page
end
