require 'spec_helper'

describe Influxer::Client do

  after(:each) do
    Rails.cache.clear
  end

  let(:conf) { Influxer.config }
  let(:client) { Influxer.client }

  it "should have config params" do
    expect(client.username).to eq conf.username
    expect(client.port).to eq conf.port
    expect(client.database).to eq conf.database
  end

  describe "cache" do
    before do
      allow_any_instance_of(Influxer::Client).to receive(:query) do |_, sql|   
        sql
      end
    end

    let(:q) { "list series" }

    after(:each) do
      conf.cache = false
    end

    it "should write data to cache" do
      conf.cache = {}

      client.cached_query(q)
      expect(Rails.cache.exist?("influxer:listseries")).to be_truthy
    end

    it "should write data to cache with expiration" do
      conf.cache = {expires_in: 1}

      client.cached_query(q)
      expect(Rails.cache.exist?("influxer:listseries")).to be_truthy
      
      sleep 2
      expect(Rails.cache.exist?("influxer:listseries")).to be_falsey
    end
  end
end