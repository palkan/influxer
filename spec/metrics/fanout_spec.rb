require 'spec_helper'

describe Influxer::Metrics do
  before do
    allow_any_instance_of(Influxer::Client).to receive(:query) do |_, sql|
      sql
    end
  end

  let(:dummy) do
    Class.new(Influxer::Metrics) do
      set_series 'dummy'
      default_scope -> { time(:hour) }
    end
  end

  let(:doomy) do
    Class.new(dummy) do
      scope :by_user, -> (id) { where(user: id) if id.present? }
      scope :hourly, -> { where(by: :hour).time(nil) }
      scope :daily, -> { where(by: :day).time(nil) }

      fanout :by, :user, :account, delimeter: "."
    end
  end

  let(:dappy) do
    Class.new(doomy) do
      fanout :user, delimeter: "_"
    end
  end

  describe "fanouts" do
    it "should work with one fanout" do
      expect(doomy.by_user(1).to_sql).to eq "select * from \"dummy.user.1\" group by time(1h)"
    end

    it "should work with several fanouts" do
      expect(dappy.by_user(1).hourly.to_sql).to eq "select * from \"dummy_by_hour_user_1\""
    end

    it "should work with regexp fanouts" do
      expect(dappy.where(dummy_id: 100).by_user(/[1-3]/).daily.to_sql)
        .to eq "select * from /^dummy_by_day_user_[1-3]$/ where (dummy_id=100)"
    end
  end

  describe "#prepare_fanout_points" do
    before do
      allow_any_instance_of(Influxer::Client).to receive(:query) do |_, _sql|
        JSON.parse(File.read('./spec/fixtures/fanout_series.json'))
      end
    end

    it "sets fanout fields values" do
      res = dappy.by_user(/\d+/).daily.to_a
      expect(res.detect { |v| v["user"] == '6' }).to include('time_spent' => 100, 'by' => 'day')
      expect(res.select { |v| v["user"] == '2' }.size).to eq 2
    end
  end
end
