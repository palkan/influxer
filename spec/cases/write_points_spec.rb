# frozen_string_literal: true

require "spec_helper"

describe "Write points" do
  before do
    stub_request(:post, /write/)
      .to_return(
        status: 204
      )
  end

  let(:metrics_class) do
    Class.new(Influxer::Metrics) do
      set_series :test

      tags :user_id

      attributes :val
    end
  end

  let(:point) { 'test,user_id=1 val="2"' }

  subject { metrics_class.write! user_id: 1, val: "2" }

  it "calls HTTP with correct params" do
    subject
    expect(
      a_request(:post, "http://localhost:8086/write")
      .with(
        query: {u: "root", p: "root", precision: "ns", db: "db"},
        body: point
      )
    ).to have_been_made
  end

  context "with retention policy" do
    it "calls HTTP with correct params" do
      metrics_class.set_retention_policy "yearly"

      subject

      expect(
        a_request(:post, "http://localhost:8086/write")
        .with(
          query: {u: "root", p: "root", precision: "ns", db: "db", rp: "yearly"},
          body: point
        )
      ).to have_been_made
    end
  end

  context "with custom db" do
    it "calls HTTP with correct params" do
      metrics_class.set_database "another_db"

      subject

      expect(
        a_request(:post, "http://localhost:8086/write")
        .with(
          query: {u: "root", p: "root", precision: "ns", db: "another_db"},
          body: point
        )
      ).to have_been_made
    end
  end

  context "with custom db" do
    it "calls HTTP with correct params" do
      metrics_class.set_precision "ms"

      subject

      expect(
        a_request(:post, "http://localhost:8086/write")
        .with(
          query: {u: "root", p: "root", precision: "ms", db: "db"},
          body: point
        )
      ).to have_been_made
    end
  end
end
