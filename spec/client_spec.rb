require 'spec_helper'

describe Influxer::Client do

  let(:conf) { Influxer.config }
  let(:client) { Influxer.client }

  it "should have config params" do
    expect(client.username).to eq conf.username
    expect(client.port).to eq conf.port
    expect(client.database).to eq conf.database
  end

end