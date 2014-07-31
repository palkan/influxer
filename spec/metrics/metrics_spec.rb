require 'spec_helper'

describe Influxer::Metrics do

  let(:metrics) { Influxer::Metrics.new }
  let(:metrics_class) { Influxer::Metrics }


  # class methods

  specify {expect(metrics_class).to respond_to :attributes}  
  specify {expect(metrics_class).to respond_to :set_series}  
  specify {expect(metrics_class).to respond_to :series}  

  # instance methods

  specify { expect(metrics).to respond_to :write }
  specify { expect(metrics).to respond_to :write! }
  specify { expect(metrics).to respond_to :persisted? }
  specify { expect(metrics).to respond_to :series}  

  # ActiveModel::Validations

  specify { expect(metrics).to respond_to :valid? }
  specify { expect(metrics).to respond_to :invalid? }
  specify { expect(metrics).to respond_to :errors }



  describe "instance methods" do

    let(:dummy_metrics) { DummyMetrics.new dummy_id: 1, user_id: 1}

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
        expect(dummy_metrics.write).to be true
        expect(dummy_metrics.persisted?).to be true
      end 

      it "should raise error if you want to write twice" do
        expect(dummy_metrics.write).to be true
        expect{dummy_metrics.write!}.to raise_error(StandardError)
      end 
    end


    describe "active_model callbacks on write" do
      it "should work" do

        Timecop.freeze(Time.local(2014,10,10,10,10,10)) do
          dummy_metrics.write!
        end

        expect(dummy_metrics.time).to eq Time.local(2014,10,10,10,10,10)
      end
    end

  end

  describe "class methods" do

    let(:dummy_metrics) do
      Class.new(Influxer::Metrics) do
        set_series :dummies        
      end
    end

    let(:dummy_with_2_series) do
      Class.new(Influxer::Metrics) do
        set_series :events, :errors       
      end
    end

    let(:dummy_with_proc_series) do
      Class.new(Influxer::Metrics) do
        attributes :user_id, :test_id
        set_series ->(metrics) { "test/#{metrics.test_id}/user/#{metrics.user_id}"}       
      end
    end



    describe "set_series" do
      it "should set series name from class name by default" do
        expect(DummyMetrics.series).to eq 'dummy'
      end

      it "should set series from subclass" do
        expect(dummy_metrics.series).to eq 'dummies'
      end

      it "should set several series" do
        expect(dummy_with_2_series.series).to eq 'events,errors'
      end


      it "should set series from proc" do
        expect(dummy_with_proc_series.series).to be_an_instance_of Proc

        m = dummy_with_proc_series.new user_id: 2, test_id:123
        expect(dummy_with_proc_series.series.call(m)).to eq "test/123/user/2"
      end
    end

  end
end