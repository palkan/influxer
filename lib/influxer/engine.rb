require 'influxer'

module Influxer
  class Engine < Rails::Engine # :nodoc:
    initializer "extend ActiveRecord with influxer" do |_app|
      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Base.send :include, Influxer::Model
      end
    end
  end
end
