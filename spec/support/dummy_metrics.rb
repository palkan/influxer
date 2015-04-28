class DummyMetrics < Influxer::Metrics # :nodoc:
  attributes :dummy_id, :user_id

  validates_presence_of :dummy_id, :user_id

  before_write -> { self.time = DateTime.now }

  scope :calc, ->(method, *args) { send(method, *args) }
end
