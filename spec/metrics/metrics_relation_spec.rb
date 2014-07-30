require 'spec_helper'

describe Influxer
  describe MetricsRelation
    let(:rel) { MetricsRelation.new DummyMetrics}

    # read
    specify { expect(rel).to respond_to :select }
    specify { expect(rel).to respond_to :not }
    specify { expect(rel).to respond_to :where }
    specify { expect(rel).to respond_to :time }
    specify { expect(rel).to respond_to :limit }
    
    #delete
    specify { expect(rel).to respond_to :delete_all }

    specify { expect(rel).to respond_to :to_sql }


    describe "select" do

      it "should select array of symbols" do
        expect(rel.select(:user_id, :dummy_id).to_sql).to eq "select user_id,dummy_id from dummy" 
      end

      it "should select string" do
        expect(rel.select("count(user_id)").to_sql).to eq "select count(user_id) from dummy" 
      end


    end

  end
end