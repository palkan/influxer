# frozen_string_literal: true

require "influxer/version"
require "active_model"
require "active_support/core_ext"

# Rails client for InfluxDB
module Influxer
  def self.active_model3?
    ActiveModel::VERSION::MAJOR == 3
  end

  require "influxer/config"
  require "influxer/client"
  require "influxer/metrics/metrics"

  module Model # :nodoc:
    require "influxer/model"
  end

  require "influxer/rails/client" if defined?(Rails)
  require "influxer/engine" if defined?(Rails)

  def self.config
    @config ||= Config.new
  end

  def self.configure
    yield(config) if block_given?
  end

  def self.client
    @client ||= Client.new
  end

  def self.reset!
    @client&.stop!
    @config = nil
    @client = nil
  end
end
