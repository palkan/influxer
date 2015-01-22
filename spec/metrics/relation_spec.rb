require 'spec_helper'

describe Influxer::Relation do
  before do
    allow_any_instance_of(Influxer::Client).to receive(:query) do |_, sql|    
      sql
    end
  end

  let(:rel) { Influxer::Relation.new DummyMetrics}
  let(:rel2) { Influxer::Relation.new DummyComplexMetrics}
  
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


  describe "merge relations" do
    it "should merge multi values" do
      r1 = rel.where(id: [1,2], dummy: 'qwe').time(:hour)
      r2 = Influxer::Relation.new(DummyMetrics).where.not(user_id: 0).group(:user_id)
      r1.merge!(r2)
      expect(r1.to_sql).to eq "select * from \"dummy\" group by time(1h),user_id where (id=1 or id=2) and (dummy='qwe') and (user_id<>0)"
    end

    it "should merge single values" do
      r1 = rel.time(:hour, fill: 0).limit(10)
      r2 = Influxer::Relation.new(DummyMetrics).merge(:doomy).limit(5)
      r1.merge!(r2)
      expect(r1.to_sql).to eq "select * from \"dummy\" merge \"doomy\" group by time(1h) fill(0) limit 5"
    end

  end

  describe "sql generation" do
    describe "from clause" do
      it "should generate valid from if no conditions" do
        expect(rel.to_sql).to eq "select * from \"dummy\""
      end
    end

    describe "select" do
      it "should select array of symbols" do
        expect(rel.select(:user_id, :dummy_id).to_sql).to eq "select user_id,dummy_id from \"dummy\"" 
      end

      it "should select string" do
        expect(rel.select("count(user_id)").to_sql).to eq "select count(user_id) from \"dummy\"" 
      end
    end

    describe "where" do
      it "should generate valid conditions from hash" do
        Timecop.freeze(Time.now) do
          expect(rel.where(user_id: 1, dummy: 'q', timer: Time.now).to_sql).to eq "select * from \"dummy\" where (user_id=1) and (dummy='q') and (timer=#{Time.now.to_i}s)" 
        end
      end

      it "should generate valid conditions from strings" do
        expect(rel.where("time > now() - 1d").to_sql).to eq "select * from \"dummy\" where (time > now() - 1d)" 
      end

      it "should handle regexps" do
        expect(rel.where(user_id: 1, dummy: /^du.*/).to_sql).to eq "select * from \"dummy\" where (user_id=1) and (dummy=~/^du.*/)" 
      end

      it "should handle ranges" do
        expect(rel.where(user_id: 1..4).to_sql).to eq "select * from \"dummy\" where (user_id>1 and user_id<4)" 
      end

      it "should handle arrays" do
        expect(rel.where(user_id: [1,2,3]).to_sql).to eq "select * from \"dummy\" where (user_id=1 or user_id=2 or user_id=3)" 
      end
    end

    describe "not" do
      it "should negate simple values" do
        expect(rel.where.not(user_id: 1, dummy: :a).to_sql).to eq "select * from \"dummy\" where (user_id<>1) and (dummy<>'a')"
      end

      it "should handle regexp" do
        expect(rel.where.not(user_id: 1, dummy: /^du.*/).to_sql).to eq "select * from \"dummy\" where (user_id<>1) and (dummy!~/^du.*/)" 
      end

      it "should handle ranges" do
        expect(rel.where.not(user_id: 1..4).to_sql).to eq "select * from \"dummy\" where (user_id<1 and user_id>4)" 
      end

      it "should handle arrays" do
        expect(rel.where.not(user_id: [1,2,3]).to_sql).to eq "select * from \"dummy\" where (user_id<>1 and user_id<>2 and user_id<>3)" 
      end
    end

    describe "merge" do
      it "should merge with one series" do
        expect(rel.merge("dubby").to_sql).to eq "select * from \"dummy\" merge \"dubby\""
      end

      it "should merge with one series as regexp" do
        expect(rel.merge(/^du[1-6]+$/).to_sql).to eq "select * from \"dummy\" merge /^du[1-6]+$/"
      end
    end

    describe "past" do
      it "should work with predefined symbols" do
         expect(rel.past(:hour).to_sql).to eq "select * from \"dummy\" where (time > now() - 1h)"
      end

      it "should work with any symbols" do
        expect(rel.past(:s).to_sql).to eq "select * from \"dummy\" where (time > now() - 1s)"
      end

      it "should work with strings" do
        expect(rel.past("3d").to_sql).to eq "select * from \"dummy\" where (time > now() - 3d)"
      end

      it "should work with numbers" do
         expect(rel.past(1.day).to_sql).to eq "select * from \"dummy\" where (time > now() - 86400s)"
      end
    end

    describe "since" do
      it "should work with datetime" do
         expect(rel.since(Time.utc(2014,12,31)).to_sql).to eq "select * from \"dummy\" where (time > 1419984000s)"
      end
    end

    describe "group" do
      it "should generate valid groups" do
        expect(rel.group(:user_id, "time(1m) fill(0)").to_sql).to eq "select * from \"dummy\" group by user_id,time(1m) fill(0)" 
      end

      describe "group by time predefined values" do
        it "should group by hour" do
          expect(rel.time(:hour).to_sql).to eq "select * from \"dummy\" group by time(1h)"
        end

        it "should group by minute" do
          expect(rel.time(:minute).to_sql).to eq "select * from \"dummy\" group by time(1m)"
        end

        it "should group by second" do
          expect(rel.time(:second).to_sql).to eq "select * from \"dummy\" group by time(1s)"
        end

        it "should group by millisecond" do
          expect(rel.time(:ms).to_sql).to eq "select * from \"dummy\" group by time(1u)"
        end

        it "should group by day" do
          expect(rel.time(:day).to_sql).to eq "select * from \"dummy\" group by time(1d)"
        end

        it "should group by week" do
          expect(rel.time(:week).to_sql).to eq "select * from \"dummy\" group by time(1w)"
        end

        it "should group by month" do
          expect(rel.time(:month).to_sql).to eq "select * from \"dummy\" group by time(30d)"
        end

        it "should group by hour and fill" do
          expect(rel.time(:month, fill: 0).to_sql).to eq "select * from \"dummy\" group by time(30d) fill(0)"
        end
      end

      it "should group by time with string value" do
        expect(rel.time("4d").to_sql).to eq "select * from \"dummy\" group by time(4d)"
      end

      it "should group by time with string value and fill null" do
        expect(rel.time("4d", fill: :null).to_sql).to eq "select * from \"dummy\" group by time(4d) fill(null)"
      end

      it "should group by time and other fields with fill null" do
        expect(rel.time("4d", fill: 0).group(:dummy_id).to_sql).to eq "select * from \"dummy\" group by time(4d),dummy_id fill(0)"
      end
    end

    describe "limit" do
      it "should generate valid limi" do
        expect(rel.limit(100).to_sql).to eq "select * from \"dummy\" limit 100" 
      end
    end

    describe "empty?" do
      after(:each) { Influxer.reset }
      it "should return false if has points" do
        Influxer.client.stub(:query) { {points: [{time: 1, id: 2}]} }
        expect(rel.empty?).to be_falsey
        expect(rel.present?).to be_truthy
      end

      it "should return true if no points" do
        Influxer.client.stub(:query) { {} }
        expect(rel.empty?).to be_truthy
        expect(rel.present?).to be_falsey
      end
    end
  end

  describe "delete_all" do
    it do
      Timecop.freeze(Time.now) do
        expect(rel.where(user_id: 1, dummy: 'q', timer: Time.now).delete_all).to eq "delete from \"dummy\" where (user_id=1) and (dummy='q') and (timer=#{Time.now.to_i}s)" 
      end
    end
  end

  describe "inspect" do

    after(:each) do
      Influxer.reset
    end
    
    it "should return correct String represantation of empty relation" do
      Influxer.client.stub(:query) { {} }
      expect(rel.inspect).to eq "#<Influxer::Relation []>"  
    end

    it "should return correct String represantation of non-empty relation" do
      Influxer.client.stub(:query){ {"dummy" => [1,2,3]} }
      expect(rel.inspect).to eq "#<Influxer::Relation [1, 2, 3]>"  
    end

     it "should return correct String represantation of non-empty large (>11) relation" do
      Influxer.client.stub(:query){ {"dummy" => [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]} } 
      expect(rel.inspect).to eq "#<Influxer::Relation [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, ...]>"  
    end
  end 
end