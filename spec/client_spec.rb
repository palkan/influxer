# frozen_string_literal: true

require "spec_helper"

describe Influxer::Client do
  let(:conf) { Influxer.config }
  subject { Influxer.client }

  describe "#initialize" do
    it "sets config database value" do
      expect(subject.config.database).to eq conf.database
    end

    it "passes config params" do
      conf.username = "admin"
      conf.port = 2222
      expect(subject.config.username).to eq "admin"
      expect(subject.config.port).to eq 2222
    end
  end

  describe "cache", :query do
    let(:q) { "list series" }
    after { Rails.cache.clear }

    
    it "does not write data to cache by default" do
      conf.cache = {}      

      subject.query(q)
      expect(Rails.cache.exist?("influxer:listseries")).to be_falsey
    end

    it "does not write data to cache if disabled" do
      conf.cache = {}
      conf.cache_enabled = false

      subject.query(q)
      expect(Rails.cache.exist?("influxer:listseries")).to be_falsey
    end

    it "writes data to cache if enabled" do
      conf.cache = {}
      conf.cache_enabled = true

      subject.query(q)
      expect(Rails.cache.exist?("influxer:listseries")).to be_truthy
    end
    
    it "should not write data to cache with expiration if disabled" do
      conf.cache = { expires_in: 90 }
      conf.cache_enabled = false

      subject.query(q)
      expect(Rails.cache.exist?("influxer:listseries")).to be_falsey      
    end

    it "should write data to cache with expiration" do
      conf.cache = {expires_in: 90}
      conf.cache_enabled = true

      subject.query(q)
      expect(Rails.cache.exist?("influxer:listseries")).to be_truthy

      Timecop.travel(1.minute.from_now)
      expect(Rails.cache.exist?("influxer:listseries")).to be_truthy

      Timecop.travel(2.minutes.from_now)
      expect(Rails.cache.exist?("influxer:listseries")).to be_falsey
    end
  end
end
