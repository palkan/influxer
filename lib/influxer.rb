require 'influxer/version'

# Rails client for InfluxDB
module Influxer
  require 'influxer/config'
  require 'influxer/client'
  require 'influxer/metrics/metrics'

  module Model # :nodoc:
    require 'influxer/model'
  end

  require 'influxer/engine'

  def self.config
    @config ||= Config.new
  end

  def self.configure
    yield(config) if block_given?
  end

  def self.client
    @client ||= Client.new
  end

  def self.reset
    @config = nil
    @client = nil
  end
end
