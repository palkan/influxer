class TestoMetrics < Influxer::Metrics
  attributes :testo_id, :user_id

  validates_presence_of :testo_id, :user_id

  before_write ->{ self.time = DateTime.now }
end