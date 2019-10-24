# frozen_string_literal: true

require "spec_helper"

describe Influxer::Metrics, :query do
  let(:metrics) { described_class.new }
  let(:dummy_metrics) { DummyMetrics.new dummy_id: 1, user_id: 1 }

  subject { metrics }

  context "class methods" do
    subject { described_class }

    specify { is_expected.to respond_to :attributes }
    specify { is_expected.to respond_to :set_series }
    specify { is_expected.to respond_to :set_retention_policy }
    specify { is_expected.to respond_to :series }
    specify { is_expected.to respond_to :write }
    specify { is_expected.to respond_to :write! }

    specify { is_expected.to respond_to :all }
    specify { is_expected.to respond_to :where }
    specify { is_expected.to respond_to :offset }
    specify { is_expected.to respond_to :time }
    specify { is_expected.to respond_to :past }
    specify { is_expected.to respond_to :since }
    specify { is_expected.to respond_to :limit }
    specify { is_expected.to respond_to :select }
    specify { is_expected.to respond_to :delete_all }
  end

  context "instance methods" do
    specify { is_expected.to respond_to :write }
    specify { is_expected.to respond_to :write! }
    specify { is_expected.to respond_to :persisted? }
    specify { is_expected.to respond_to :series }
    if Influxer.active_model3?
      specify { is_expected.to be_a Influxer::ActiveModel3::Model }
    else
      specify { is_expected.to be_a ActiveModel::Model }
    end
  end

  describe "#initialize" do
    it "assigns initial values in constructor" do
      m = DummyMetrics.new(dummy_id: 1)
      expect(m.dummy_id).to eq 1
    end
  end

  describe "#write" do
    it "doesn't write if required attribute is missing" do
      m = DummyMetrics.new(dummy_id: 1)
      expect(client).not_to receive(:write_point)
      expect(m.write).to be false
      expect(m.errors.size).to eq(1)
    end

    it "raises error if required attribute is missing" do
      expect { DummyMetrics.new(user_id: 1).write! }.to raise_error(Influxer::MetricsInvalid)
    end

    it "raises error if you want to write twice" do
      expect(dummy_metrics.write).to be_truthy
      expect { dummy_metrics.write! }.to raise_error(Influxer::MetricsError)
    end

    it "writes successfully" do
      expect(client).to receive(:write_point).with("dummy", anything, nil, nil, nil)
      expect(dummy_metrics.write).to be_truthy
      expect(dummy_metrics.persisted?).to be_truthy
    end

    context "after_write callback" do
      it "sets current time" do
        Timecop.freeze(Time.local(2015))
        dummy_metrics.write!
        expect(dummy_metrics.timestamp).to eq Time.local(2015)
      end
    end
  end

  describe "#series" do
    let(:dummy_metrics) do
      Class.new(described_class) do
        set_series :dummies
        attributes :user_id, :dummy_id
      end
    end

    let(:dummy_metrics_2) do
      Class.new(described_class) do
        set_series "dummy \"A\""
      end
    end

    let(:dummy_metrics_3) do
      Class.new(described_class) do
        set_series(/^.*$/)
      end
    end

    let(:dummy_with_2_series) do
      Class.new(described_class) do
        set_series :events, :errors
      end
    end

    let(:dummy_with_2_series_quoted) do
      Class.new(described_class) do
        set_series "dummy \"A\"", "dummy \"B\""
      end
    end

    let(:dummy_with_proc_series) do
      Class.new(described_class) do
        attributes :user_id, :test_id
        set_series ->(metrics) { "test/#{metrics.test_id}/user/#{metrics.user_id}" }
      end
    end

    it "sets series name from class name by default" do
      expect(DummyMetrics.new.series).to eq "\"dummy\""
    end

    it "sets series from subclass" do
      expect(dummy_metrics.new.series).to eq "\"dummies\""
    end

    it "sets series as regexp" do
      expect(dummy_metrics_3.new.series).to eq "/^.*$/"
    end

    it "quotes series" do
      expect(dummy_metrics_2.new.series).to eq "\"dummy \\\"A\\\"\""
    end

    it "set several series" do
      expect(dummy_with_2_series.new.series).to eq "merge(\"events\",\"errors\")"
    end

    it "quotes several series" do
      expect(dummy_with_2_series_quoted.new.series)
        .to eq "merge(\"dummy \\\"A\\\"\",\"dummy \\\"B\\\"\")"
    end

    it "sets series from proc" do
      expect(dummy_with_proc_series.series).to be_an_instance_of Proc

      m = dummy_with_proc_series.new user_id: 2, test_id: 123
      expect(m.series).to eq "\"test/123/user/2\""
    end
  end

  describe "#quoted_series" do
    context "with retention policy" do
      let(:dummy_with_retention_policy) do
        Class.new(described_class) do
          attributes :user_id, :test_id
          set_series :dummies
          set_retention_policy :week
        end
      end

      it "sets retention policy" do
        expect(dummy_with_retention_policy.retention_policy).to eq :week
      end

      it "sets quoted series with retention policy" do
        expect(dummy_with_retention_policy.quoted_series).to eq "\"week\".\"dummies\""
      end
    end
  end

  describe ".tags" do
    let(:dummy1) { Class.new(DummyMetrics) }
    let!(:dummy2) do
      Class.new(dummy1) do
        tags :zone
      end
    end

    it "inherits tags" do
      expect(dummy2.tag_names).to include("dummy_id", "host", "zone")
    end

    it "clones tags" do
      dummy1.tags :status
      expect(dummy1.tag_names).to include("status")
      expect(dummy2.tag_names).not_to include("status")
    end
  end

  describe "#dup" do
    let(:point) { DummyMetrics.new(user_id: 1, dummy_id: 2) }
    subject { point.dup }

    specify { expect(subject.user_id).to eq 1 }
    specify { expect(subject.dummy_id).to eq 2 }

    context "dup is not persisted" do
      before { point.write }
      specify { expect(subject.persisted?).to be_falsey }
    end
  end

  describe ".write" do
    let(:dummy_metrics) do
      Class.new(described_class) do
        set_series :dummies
        tags :dummy_id, :host
        attributes :user_id
      end
    end

    it "write data and return point" do
      expect(client)
        .to receive(:write_point).with(
          "dummies",
          {tags: {dummy_id: 2, host: "test"}, values: {user_id: 1}, timestamp: nil},
          nil,
          nil,
          nil
        )

      point = dummy_metrics.write(user_id: 1, dummy_id: 2, host: "test")
      expect(point.persisted?).to be_truthy
      expect(point.user_id).to eq 1
      expect(point.dummy_id).to eq 2
    end

    it "test write data with time and return point" do
      timestamp_test = Time.now
      expected_time = (timestamp_test.to_r * 1_000_000_000).to_i

      expect(client)
        .to receive(:write_point).with(
          "dummies",
          {tags: {dummy_id: 2, host: "test"}, values: {user_id: 1}, timestamp: expected_time},
          nil,
          nil,
          nil
        )

      point = dummy_metrics.write(user_id: 1, dummy_id: 2, host: "test", timestamp: timestamp_test)
      expect(point.persisted?).to be_truthy
      expect(point.user_id).to eq 1
      expect(point.dummy_id).to eq 2
      expect(point.timestamp).to eq timestamp_test
    end

    it "test write data with string time" do
      base_time = Time.now
      timestamp_test = base_time.to_s

      expect(client)
        .to receive(:write_point).with(
          "dummies",
          {tags: {dummy_id: 2, host: "test"}, values: {user_id: 1}, timestamp: (base_time.to_i * 1_000_000_000).to_i},
          nil,
          nil,
          nil
        )

      point = dummy_metrics.write(user_id: 1, dummy_id: 2, host: "test", timestamp: timestamp_test)
      expect(point.persisted?).to be_truthy
      expect(point.user_id).to eq 1
      expect(point.dummy_id).to eq 2
      expect(point.timestamp).to eq(timestamp_test)
    end

    context "with non-default precision", precision: :s do
      it "test write timestamp with the specified precision" do
        base_time = Time.now
        timestamp_test = base_time.to_s
        expected_time = base_time.to_i

        expect(client)
          .to receive(:write_point).with(
            "dummies",
            {tags: {dummy_id: 2, host: "test"}, values: {user_id: 1}, timestamp: expected_time},
            nil,
            nil,
            nil
          )

        point = dummy_metrics.write(user_id: 1, dummy_id: 2, host: "test", timestamp: timestamp_test)
        expect(point.persisted?).to be_truthy
        expect(point.user_id).to eq 1
        expect(point.dummy_id).to eq 2
        expect(point.timestamp).to eq(timestamp_test)
      end
    end

    context "when duration suffix is enabled", :duration_suffix do
      it "test write timestamp without suffix" do
        base_time = Time.now
        timestamp_test = base_time.to_s
        expected_time = (base_time.to_i * 1_000_000_000).to_i

        expect(client)
          .to receive(:write_point).with(
            "dummies",
            {tags: {dummy_id: 2, host: "test"}, values: {user_id: 1}, timestamp: expected_time},
            nil,
            nil,
            nil
          )

        point = dummy_metrics.write(user_id: 1, dummy_id: 2, host: "test", timestamp: timestamp_test)
        expect(point.persisted?).to be_truthy
        expect(point.user_id).to eq 1
        expect(point.dummy_id).to eq 2
        expect(point.timestamp).to eq(timestamp_test)
      end
    end

    it "doesn't write data and return false if invalid" do
      expect(client).not_to receive(:write_point)
      expect(DummyMetrics.write(dummy_id: 2)).to be false
    end
  end

  describe ".all" do
    it "responds with relation" do
      expect(described_class.all).to be_a Influxer::Relation
    end
  end
end
