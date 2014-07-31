module Influxer
  class Config
    attr_accessor :database,
                  :host,
                  :port,
                  :username,
                  :password,
                  :use_ssl,
                  :async,
                  :retry

    def initialize

    end

  end
end