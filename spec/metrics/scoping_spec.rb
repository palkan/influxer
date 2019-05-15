# frozen_string_literal: true

require "spec_helper"

describe Influxer::Metrics, :query do
  let(:klass) do
    Class.new(Influxer::Metrics) do
      set_series "dummy"
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
      scope :by_user, ->(id) { where(user_id: id) if id.present? }
      scope :hourly, -> { time(:hour) }
      scope :daily, -> { time(:day) }
    end
  end

  describe "default scope" do
    it "works without default scope" do
      expect(klass.all.to_sql).to eq "select * from \"dummy\""
    end

    it "works with default scope" do
      expect(dummy.all.to_sql).to eq "select * from \"dummy\" group by time(1h)"
    end

    it "works with unscoped" do
      expect(dummy.unscoped.to_sql).to eq "select * from \"dummy\""
    end

    it "works with several defaults" do
      expect(dappy.where(user_id: 1).to_sql)
        .to eq "select * from \"dummy\" where (user_id = 1) group by time(1h) limit 100"
    end
  end

  describe "named scope" do
    it "works with named scope" do
      expect(doomy.by_user(1).to_sql)
        .to eq "select * from \"dummy\" where (user_id = 1) group by time(1h) limit 100"
    end

    it "works with named scope with empty relation" do
      expect(doomy.by_user(nil).to_sql).to eq "select * from \"dummy\" group by time(1h) limit 100"
    end

    it "works with several scopes" do
      expect(doomy.where(dummy_id: 100).by_user([1, 2, 3]).daily.to_sql)
        .to eq "select * from \"dummy\" where (dummy_id = 100) and (user_id = 1 or user_id = 2 or user_id = 3) group by time(1d) limit 100"
    end
  end
end
