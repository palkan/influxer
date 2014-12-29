module Influxer
  class Config
    attr_accessor :database,
                  :host,
                  :port,
                  :username,
                  :password,
                  :use_ssl,
                  :async,
                  :cache,
                  :retry,
                  :time_precision,
                  :initial_delay,
                  :max_delay,
                  :read_timeout,
                  :write_timeout

    def initialize
      @database = 'db'
      @host = 'localhost'
      @port = 8083
      @use_ssl = false
      @async = true
      @cache = false
      @retry = false
      @time_precision = 's'
      @max_delay = 30
      @initial_delay = 0.01
      @read_timeout = 30
      @write_timeout = 5 

      config_path = Rails.root.join("config","influxdb.yml")
      
      config = {}

      if File.file? config_path
        config = YAML.load_file(config_path)[Rails.env] || {}
      end

      unless Rails.application.try(:secrets).nil?
        config.merge! Rails.application.secrets.influxdb
      end

      config.each do |key, val| 
        self.send("#{key}=",val)
      end

      # we want pass @cache value as options to cache store, so we want it to be a Hash
      if @cache == true
        @cache = {}
      end
    end
  end
end