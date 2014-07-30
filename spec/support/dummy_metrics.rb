class DummyMetrics < Influxer::Metrics
  attributes :dummy_id, :user_id

  validates_presence_of :dummy_id, :user_id

  before_write ->{ self.time = DateTime.now }
end