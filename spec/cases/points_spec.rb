# frozen_string_literal: true

require "spec_helper"

describe DummyMetrics do
  before do
    stub_request(:get, "http://localhost:8086/query")
      .with(
        query: {q: 'select * from "dummy"', u: "root", p: "root", precision: "ns", db: "db"}
      )
      .to_return(body: fixture_file)
  end

  context "single_series" do
    let(:fixture_file) { File.read("./spec/fixtures/single_series.json") }

    context "default format (values merged with tags)" do
      subject { described_class.all.to_a }

      it "returns array of hashes" do
        expect(subject.first).to include("host" => "server01", "region" => "us-west", "value" => 0.64)
        expect(subject.second).to include("host" => "server01", "region" => "us-west", "value" => 0.93)
      end
    end
  end

  context "empty result" do
    let(:fixture_file) { File.read("./spec/fixtures/empty_result.json") }

    subject { described_class.all.to_a }

    it "returns empty array" do
      expect(subject).to eq []
    end
  end
end
