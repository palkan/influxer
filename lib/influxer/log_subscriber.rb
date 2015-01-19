module Influxer
  class LogSubscriber < ActiveSupport::LogSubscriber
    def sql(event)
      return unless logger.debug?

      payload = event.payload

      name  = "#{payload[:name]} (#{event.duration.round(1)}ms)"
      sql   = payload[:sql]

      name = color(name, BLUE, true)
      sql  = color(sql, nil, true)
      
      debug "  #{name}  #{sql}"
    end

    def logger
      Rails.logger
    end
  end
end

Influxer::LogSubscriber.attach_to :influxer