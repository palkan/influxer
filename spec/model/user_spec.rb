# frozen_string_literal: true

require "spec_helper"

describe User do
  let(:user) { described_class.create age: 20, gender: 1, email: "user@example.com" }
  subject { user }

  specify { is_expected.to respond_to :metrics }
  specify { is_expected.to respond_to :visits_metrics }
  specify { is_expected.to respond_to :action_metrics }
  specify { is_expected.to respond_to :custom_metrics }

  describe "#metrics" do
    subject { user.metrics.new }

    it "add foreign key" do
      expect(subject.user_id).to eq user.id
    end
  end

  describe "#visits_metrics" do
    subject { user.visits_metrics.new }

    it "adds inherited attributes" do
      expect(subject.age).to eq 20
      expect(subject.gender).to eq 1
    end
  end

  describe "#action_metrics" do
    subject { user.action_metrics.new }

    it "adds custom foreign key" do
      expect(subject.user).to eq user.id
    end
  end

  describe "#custom_metrics" do
    subject { user.custom_metrics.new }

    it "doesn't add foreign key" do
      expect(subject.user_id).to be_nil
    end
  end
end
