require 'spec_helper'

describe DummyMetrics do
  before do
    stub_request(:get, "http://localhost:8086/query")
      .with(
        query: { q: 'select * from "dummy"', u: "root", p: "root", precision: 'ns', db: 'db' }
      )
      .to_return(body: fixture_file)
  end

  context "single_series" do
    let(:fixture_file) { File.read('./spec/fixtures/single_series.json') }

    context "default format (values merged with tags)" do
      subject { described_class.all.to_a }

      it 'returns an array of structs' do
        expect(subject.first).to be_a Struct
        expect(subject.second).to be_a Struct
      end

      it "responds to all the key elements of the parsed series" do
        expected_methods = [:host, :region, :value]

        subject.each do |object|
          expect(object).to respond_to(*expected_methods)
        end
      end

      it 'returns the expected value for all the key elements of the parsed series' do
        a_series = { "host" => "server01", "region" => "us-west", "value" => 0.93 }
        parsed_series = subject.last

        a_series.each_pair do |key, value|
          expect(parsed_series.public_send(key.to_sym)).to eq value
        end
      end
    end
  end

  context "empty result" do
    let(:fixture_file) { File.read('./spec/fixtures/empty_result.json') }

    subject { described_class.all.to_a }

    it "returns empty array" do
      expect(subject).to eq []
    end
  end
end
