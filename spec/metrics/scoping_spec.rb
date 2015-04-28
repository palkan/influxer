require 'spec_helper'

describe Influxer::Metrics do
  before do
    allow_any_instance_of(Influxer::Client).to receive(:query) do |_, sql|
      sql
    end
  end

  let(:klass) do
    Class.new(Influxer::Metrics) do
      set_series 'dummy'
    end
  end

  let(:dummy) do
    Class.new(klass) do
      default_scope -> { time(:hour) }
    end
  end

  let(:dappy) do
    Class.new(dummy) do
      default_scope -> { limit(100) }
    end
  end

  let(:doomy) do
    Class.new(dappy) do
      scope :by_user, -> (id) { where(user_id: id) if id.present? }
      scope :hourly, -> { time(:hour) }
      scope :daily, -> { time(:day) }
    end
  end

  describe "default scope" do
    it "should work without default scope" do
      expect(klass.all.to_sql).to eq "select * from \"dummy\""
    end

    it "should work with default scope" do
      expect(dummy.all.to_sql).to eq "select * from \"dummy\" group by time(1h)"
    end

    it "should work with unscoped" do
      expect(dummy.unscoped.to_sql).to eq "select * from \"dummy\""
    end

    it "should work with several defaults" do
      expect(dappy.where(user_id: 1).to_sql)
        .to eq "select * from \"dummy\" group by time(1h) where (user_id=1) limit 100"
    end
  end

  describe "named scope" do
    it "should work with named scope" do
      expect(doomy.by_user(1).to_sql)
        .to eq "select * from \"dummy\" group by time(1h) where (user_id=1) limit 100"
    end

    it "should work with named scope with empty relation" do
      expect(doomy.by_user(nil).to_sql).to eq "select * from \"dummy\" group by time(1h) limit 100"
    end

    it "should work with several scopes" do
      expect(doomy.where(dummy_id: 100).by_user([1, 2, 3]).daily.to_sql)
        .to eq "select * from \"dummy\" group by time(1d) where (dummy_id=100) and (user_id=1 or user_id=2 or user_id=3) limit 100"
    end
  end
end
