class VisitsMetrics < Influxer::Metrics
  tags :user_id, :gender
  attributes :age, :page
end
