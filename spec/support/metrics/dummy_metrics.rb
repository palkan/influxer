# frozen_string_literal: true

class DummyMetrics < Influxer::Metrics # :nodoc:
  tags :dummy_id, :host
  attributes :user_id

  validates_presence_of :dummy_id, :user_id

  before_write -> { self.timestamp = Time.now }

  scope :calc, ->(method, *args) { send(method, *args) }
end
