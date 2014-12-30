require 'spec_helper'

describe Influxer::Client do

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
      expect(Rails.cache.exist?(q)).to be_truthy
    end
  end
end