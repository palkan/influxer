require 'spec_helper'

describe Influxer::Relation do
    let(:rel) { Influxer::Relation.new DummyMetrics}
    
    specify { expect(rel).to respond_to :write}
    specify { expect(rel).to respond_to :build}

    # read
    specify { expect(rel).to respond_to :select }
    specify { expect(rel).to respond_to :where }
    specify { expect(rel).to respond_to :limit }
    specify { expect(rel).to respond_to :group }
    
    #delete
    specify { expect(rel).to respond_to :delete_all }

    specify { expect(rel).to respond_to :to_sql }


    describe "sql generation" do
      describe "select" do
        it "should select array of symbols" do
          expect(rel.select(:user_id, :dummy_id).to_sql).to eq "select user_id,dummy_id from dummy" 
        end

        it "should select string" do
          expect(rel.select("count(user_id)").to_sql).to eq "select count(user_id) from dummy" 
        end
      end

      describe "where" do
        it "should generate valid conditions from hash" do
          Timecop.freeze(Time.now) do
            expect(rel.where(user_id: 1, dummy: 'q', timer: Time.now).to_sql).to eq "select * from dummy where (user_id=1) and (dummy='q') and (timer=#{Time.now.to_i}s)" 
          end
        end

        it "should generate valid conditions from strings" do
          expect(rel.where("time > now() - 1d").to_sql).to eq "select * from dummy where (time > now() - 1d)" 
        end
      end

      describe "group" do
        it "should generate valid groups" do
          expect(rel.group(:user_id, "time(1m) fill(0)").to_sql).to eq "select * from dummy group by user_id,time(1m) fill(0)" 
        end
      end

      describe "limit" do
        it "should generate valid limi" do
          expect(rel.limit(100).to_sql).to eq "select * from dummy limit 100" 
        end
      end
    end

    describe "inspect" do

      after(:each) do
        Influxer.reset
      end
      
      it "should return correct String represantation of empty relation" do
        Influxer.client.stub(:query) { [] }
        expect(rel.inspect).to eq "#<Influxer::Relation []>"  
      end

      it "should return correct String represantation of non-empty relation" do
        Influxer.client.stub(:query){ [1,2,3] }
        expect(rel.inspect).to eq "#<Influxer::Relation [1, 2, 3]>"  
      end

       it "should return correct String represantation of non-empty large (>11) relation" do
        Influxer.client.stub(:query){ [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]}
        expect(rel.inspect).to eq "#<Influxer::Relation [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, ...]>"  
      end
    end 
end