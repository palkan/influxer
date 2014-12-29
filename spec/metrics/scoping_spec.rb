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

  let(:dappy) do
    Class.new(dummy) do
      default_scope -> { limit(100) }
    end
  end


  describe "default scope" do
    it "should work with default scope" do
      expect(dummy.all.to_sql).to eq "select * from \"dummy\" group by time(1h)"
    end

    it "should work with unscoped" do
      expect(dummy.unscoped.to_sql).to eq "select * from \"dummy\""
    end

    it "should work with several defaults" do
      expect(dappy.where(user_id:1).to_sql).to eq "select * from \"dummy\" group by time(1h) where (user_id=1) limit 100"
    end
  end

  describe "named scope" do

  end
end