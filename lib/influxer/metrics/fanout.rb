module Influxer
  module Fanout # :nodoc: all
    extend ActiveSupport::Concern

    included do
      class_attribute :fanouts, :fanouts_by_name, :fanout_options
      self.fanouts = []
      self.fanouts_by_name = {} # to use within `fanout?`
      self.fanout_options = { delimeter: "_" }
    end

    module ClassMethods
      # Define fanouts for metrics as array of keys.
      # Order of keys is important.
      # Fanout delimeter can be set with 'delimiter' option (defaults to '_').
      #
      #   class MyMetrics < Influxer::Metrics
      #     set_series "my_points"
      #     fanout :account_id, :user_id
      #   end
      #
      #   MyMetrics.where(user_id: 1).where(account_id: 10)
      #   # select * from my_points_account_id_10_user_id_1
      #
      #   class MyMetrics < Influxer::Metrics
      #     set_series "my_points"
      #     fanout :account_id, :user_id, delimiter: "."
      #   end
      #
      #   MyMetrics.where(user_id: 1).where(account_id: 10).where("req_time > 1000")
      #   # select * from my_points.account_id.10.user_id.1 where req_time > 1000

      def fanout(*args, **hargs)
        self.fanout_options = fanout_options.merge hargs

        names = args.map(&:to_s)

        self.fanouts = (fanouts + names).uniq

        names_hash = {}
        names.each do |name|
          names_hash[name] = 1
        end

        self.fanouts_by_name = fanouts_by_name.merge names_hash
      end

      def fanout?(key)
        fanouts_by_name.key?(key.to_s)
      end

      def fanout_rxp
        return @fanout_rxp unless @fanout_rxp.nil?
        series_name = Regexp.escape(quoted_series[1..-2])
        del = Regexp.escape(fanout_options[:delimeter])
        rstr = "^#{series_name}"
        fanouts.each do |f_name|
          rstr += "(?:#{del}#{Regexp.escape(f_name)}#{del}(?<#{f_name}>[^#{del}]+))?"
        end
        rstr += "$"
        @fanout_rxp = Regexp.new(rstr)
      end
    end
  end
end
