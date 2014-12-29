require 'influxer/version'

module Influxer
  require 'influxer/config'
  require 'influxer/client'
  require 'influxer/metrics/metrics'
  require 'influxer/metrics/relation/time_query'
  require 'influxer/metrics/relation'

  module Model
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
