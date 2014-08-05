require 'spec_helper'

describe Influxer::Config do

  let(:conf) { Influxer.config }

  it "should load config from file" do
    expect(conf.retry).to eq 5
    expect(conf.host).to eq "test.host"   
  end

  unless Rails.application.try(:secrets).nil?
    it "should load config from secrets" do
      expect(conf.username).to eq "test"
      expect(conf.password).to eq "test"   
    end
  end
end
