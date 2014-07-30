require 'spec_helper'

describe DummyMetrics do

  let(:metrics) { DummyMetrics.new user_id: 1, dummy_id: 1}

  specify { expect(metrics).to respond_to :write }
  specify { expect(metrics).to respond_to :write! }
  specify { expect(metrics).to respond_to :persisted? }
  
  # ActiveModel::Validations

  specify { expect(metrics).to respond_to :valid? }
  specify { expect(metrics).to respond_to :invalid? }
  specify { expect(metrics).to respond_to :errors }

  describe "write method" do
    it "should not write if required attribute is missing" do
      m = DummyMetrics.new(dummy_id: 1)
      expect(m.write).to be false
      expect(m.errors.size).to eq(1)
    end 

    it "should raise error if required attribute is missing" do
      expect{DummyMetrics.new(user_id: 1).write!}.to raise_error(StandardError)    
    end 

    it "should write successfully when all required attributes are set" do
      expect(metrics.write).to be true
      expect(metrics.persisted?).to be true
    end 

    it "should raise error if you want to write twice" do
      expect(metrics.write).to be true
      expect{metrics.write!}.to raise_error(StandardError)
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