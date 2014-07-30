require 'spec_helper'

describe Metrics do

  let(:metrics) { TestoMetrics.new user_id: 1, testo_id: 1}

  specify { expect(metrics).to respond_to? :write }
  specify { expect(metrics).to respond_to? :write! }
  specify { expect(metrics).to respond_to? :persisted? }
  
  # ActiveModel::Validations

  specify { expect(metrics).to respond_to? :valid? }
  specify { expect(metrics).to respond_to? :invalid? }
  specify { expect(metrics).to respond_to? :error }

  describe "write method" do
    it "should not write if required attribute is missing" do
      expect(TestoMetrics.new(testo_id: 1)).to be_false
    end 

    it "should raise error if required attribute is missing" do
      expect(TestoMetrics.new(user_id: 1).write!).to raise_error    
    end 

    it "should write successfully when all required attributes are set" do
      expect(metrics.write).to be_true
      expect(metrics.persisted?).to be_true
    end 

    it "should raise error if you want to write twice" do
      expect(metrics.write).to be_true
      expect{metrics.write!}.to raise_error
    end 
  end


  describe "before_write filter" do
    it "should work" do

      Timecop.freeze(Time.local(2014,10,10,10,10,10)) do
        metrics.write!
      end

      expect(metrics.time).to eq Time.local(2014,10,10,10,10,10)
    end
  end


end