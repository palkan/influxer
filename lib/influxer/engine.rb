require 'influxer'
require 'rails'

module Influxer
  class Engine < Rails::Engine
    initializer "extend ActiveRecord with influxer" do |app|
      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Base.send :include, Influxer::Model
      end
    end    
  end
end