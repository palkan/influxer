require 'spec_helper'

describe Influxer::Metrics, :query do
  let(:metrics) { described_class.new }
  let(:dummy_metrics) { DummyMetrics.new dummy_id: 1, user_id: 1 }

  subject { metrics }

  context "class methods" do
    subject { described_class }

    specify { is_expected.to respond_to :attributes }
    specify { is_expected.to respond_to :set_series }
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
    specify { is_expected.to be_a ActiveModel::Model }
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
      expect(client).to receive(:write_point).with("dummy", anything)
      expect(dummy_metrics.write).to be_truthy
      expect(dummy_metrics.persisted?).to be_truthy
    end

    context "after_write callback" do
      it "sets current time" do
        Timecop.freeze(Time.local(2015))
        dummy_metrics.write!
        expect(dummy_metrics.timestamp).to eq Time.local(2015).to_i
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
        set_series /^.*$/
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
      expect(dummy_metrics_3.new.series).to eq '/^.*$/'
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

  describe ".tags" do
    let(:dummy1) { Class.new(DummyMetrics) }
    let!(:dummy2) do
      Class.new(dummy1) do
        tags :zone
      end
    end

    it "inherits tags" do
      expect(dummy2.tag_names).to include('dummy_id', 'host', 'zone')
    end

    it "clones tags" do
      dummy1.tags :status
      expect(dummy1.tag_names).to include('status')
      expect(dummy2.tag_names).not_to include('status')
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
        .to receive(:write_point).with("dummies", tags: { dummy_id: 2, host: 'test' }, values: { user_id: 1 })

      point = dummy_metrics.write(user_id: 1, dummy_id: 2, host: 'test')
      expect(point.persisted?).to be_truthy
      expect(point.user_id).to eq 1
      expect(point.dummy_id).to eq 2
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
