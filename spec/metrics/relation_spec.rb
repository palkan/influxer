# frozen_string_literal: true

require "spec_helper"

describe Influxer::Relation, :query do
  let(:rel) { Influxer::Relation.new DummyMetrics }
  let(:rel2) { Influxer::Relation.new DummyComplexMetrics }

  context "instance methods" do
    subject { rel }

    specify { is_expected.to respond_to :write }
    specify { is_expected.to respond_to :select }
    specify { is_expected.to respond_to :where }
    specify { is_expected.to respond_to :limit }
    specify { is_expected.to respond_to :group }
    specify { is_expected.to respond_to :delete_all }
    specify { is_expected.to respond_to :to_sql }
  end

  describe "#build" do
    specify { expect(rel.build).to be_a DummyMetrics }
    specify { expect(rel.new).to be_a DummyMetrics }
  end

  describe "#merge!" do
    it "merge multi values" do
      r1 = rel.where(id: [1, 2], dummy: "qwe").time(:hour)
      r2 = Influxer::Relation.new(DummyMetrics).where.not(user_id: 0).group(:user_id).order(user_id: :asc)
      r1.merge!(r2)
      expect(r1.to_sql)
        .to eq "select * from \"dummy\" where (id = 1 or id = 2) and (dummy = 'qwe') and (user_id <> 0) " \
               "group by time(1h), user_id order by user_id asc"
    end

    it "merge single values" do
      r1 = rel.time(:hour, fill: 0).slimit(10)
      r2 = Influxer::Relation.new(DummyMetrics).group(:dummy_id).offset(10).slimit(5)
      r1.merge!(r2)
      expect(r1.to_sql).to eq "select * from \"dummy\" group by time(1h), dummy_id fill(0) offset 10 slimit 5"
    end
  end

  context "sql generation" do
    describe "#from" do
      it "generates valid from if no conditions" do
        expect(rel.to_sql).to eq "select * from \"dummy\""
      end

      it "generates sql using custom from clause" do
        expect(rel.from(:doomy).to_sql).to eq "select * from \"doomy\""
      end
    end

    describe "#select" do
      it "select array of symbols" do
        expect(rel.select(:user_id, :dummy_id).to_sql).to eq "select user_id, dummy_id from \"dummy\""
      end

      it "select string" do
        expect(rel.select("count(user_id)").to_sql).to eq "select count(user_id) from \"dummy\""
      end

      it "select expression" do
        expect(rel.select("(value + 6) / 10").to_sql).to eq "select (value + 6) / 10 from \"dummy\""
      end
    end

    describe "#where" do
      it "generate valid conditions from hash" do
        Timecop.freeze(Time.now)
        expect(rel.where(user_id: 1, dummy: "q", time: Time.now).to_sql).to eq "select * from \"dummy\" where (user_id = 1) and (dummy = 'q') and (time = #{(Time.now.to_r * 1_000_000_000).to_i})"
      end

      it "generate valid conditions from strings" do
        expect(rel.where("time > now() - 1d").to_sql).to eq "select * from \"dummy\" where (time > now() - 1d)"
      end

      it "handle regexps" do
        expect(rel.where(user_id: 1, dummy: /^du.*/).to_sql).to eq "select * from \"dummy\" where (user_id = 1) and (dummy =~ /^du.*/)"
      end

      it "handle dates" do
        expect(rel.where(time: Date.new(2015)).to_sql).to eq "select * from \"dummy\" where (time = #{(Date.new(2015).to_time.to_r * 1_000_000_000).to_i})"
      end

      it "handle date times" do
        expect(rel.where(time: DateTime.new(2015)).to_sql).to eq "select * from \"dummy\" where (time = #{(DateTime.new(2015).to_time.to_r * 1_000_000_000).to_i})"
      end

      it "handle date ranges" do
        expect(rel.where(time: Date.new(2015)..Date.new(2016)).to_sql).to eq "select * from \"dummy\" where (time >= #{(Date.new(2015).to_time.to_r * 1_000_000_000).to_i} and time <= #{(Date.new(2016).to_time.to_r * 1_000_000_000).to_i})"
      end

      it "handle date time ranges" do
        expect(rel.where(time: DateTime.new(2015)..DateTime.new(2016)).to_sql).to eq "select * from \"dummy\" where (time >= #{(DateTime.new(2015).to_time.to_r * 1_000_000_000).to_i} and time <= #{(DateTime.new(2016).to_time.to_r * 1_000_000_000).to_i})"
      end

      it "handle inclusive ranges" do
        expect(rel.where(user_id: 1..4).to_sql).to eq "select * from \"dummy\" where (user_id >= 1 and user_id <= 4)"
      end

      it "handle exclusive range" do
        expect(rel.where(user_id: 1...4).to_sql).to eq "select * from \"dummy\" where (user_id >= 1 and user_id < 4)"
      end

      it "handle arrays" do
        expect(rel.where(user_id: [1, 2, 3]).to_sql).to eq "select * from \"dummy\" where (user_id = 1 or user_id = 2 or user_id = 3)"
      end

      it "handle empty arrays", :aggregate_failures do
        expect(rel.where(user_id: []).to_sql).to eq "select * from \"dummy\" where (time < 0)"
        expect(rel.to_a).to eq []
      end

      context "with timestamp duration", :duration_suffix do
        it "adds ns suffix to times" do
          expect(rel.where(time: DateTime.new(2015)).to_sql).to eq "select * from \"dummy\" where (time = #{(DateTime.new(2015).to_time.to_r * 1_000_000_000).to_i}ns)"
        end

        context "with different time_precision", precision: :s do
          it "adds s suffix to times" do
            expect(rel.where(time: DateTime.new(2015)).to_sql).to eq "select * from \"dummy\" where (time = #{DateTime.new(2015).to_time.to_i}s)"
          end
        end

        context "with unsupported time_precision" do
          around do |ex|
            old_precision = Influxer.config.time_precision
            Influxer.config.time_precision = "h"
            ex.run
            Influxer.config.time_precision = old_precision
          end

          it "casts to ns with suffix" do
            expect(rel.where(time: DateTime.new(2015)).to_sql).to eq "select * from \"dummy\" where (time = #{(DateTime.new(2015).to_time.to_r * 1_000_000_000).to_i}ns)"
          end
        end
      end

      context "with different time_precision", precision: :s do
        it "casts to correct numeric representation" do
          expect(rel.where(time: DateTime.new(2015)).to_sql).to eq "select * from \"dummy\" where (time = #{DateTime.new(2015).to_time.to_i})"
        end
      end

      context "with tags" do
        it "integer tag values" do
          expect(rel.where(dummy_id: 10).to_sql).to eq "select * from \"dummy\" where (dummy_id = '10')"
        end

        it "array tag values" do
          expect(rel.where(dummy_id: [10, "some"]).to_sql).to eq "select * from \"dummy\" where (dummy_id = '10' or dummy_id = 'some')"
        end

        it "nil value" do
          expect(rel.where(dummy_id: nil).to_sql).to eq "select * from \"dummy\" where (dummy_id !~ /.*/)"
        end
      end
    end

    describe "#not" do
      it "negate simple values" do
        expect(rel.where.not(user_id: 1, dummy: :a).to_sql).to eq "select * from \"dummy\" where (user_id <> 1) and (dummy <> 'a')"
      end

      it "handle regexp" do
        expect(rel.where.not(user_id: 1, dummy: /^du.*/).to_sql).to eq "select * from \"dummy\" where (user_id <> 1) and (dummy !~ /^du.*/)"
      end

      it "handle inclusive ranges" do
        expect(rel.where.not(user_id: 1..4).to_sql).to eq "select * from \"dummy\" where (user_id < 1 or user_id > 4)"
      end

      it "handle exclusive ranges" do
        expect(rel.where.not(user_id: 1...4).to_sql).to eq "select * from \"dummy\" where (user_id < 1 or user_id >= 4)"
      end

      it "handle arrays" do
        expect(rel.where.not(user_id: [1, 2, 3]).to_sql).to eq "select * from \"dummy\" where (user_id <> 1 and user_id <> 2 and user_id <> 3)"
      end

      it "handle empty arrays", :aggregate_failures do
        expect(rel.where.not(user_id: []).to_sql).to eq "select * from \"dummy\" where (time >= 0)"
      end

      context "with tags" do
        it "nil value" do
          expect(rel.not(dummy_id: nil).to_sql).to eq "select * from \"dummy\" where (dummy_id =~ /.*/)"
        end
      end
    end

    describe "#none" do
      it "returns empty array", :aggregate_failures do
        expect(rel.none.to_sql).to eq "select * from \"dummy\" where (time < 0)"
        expect(rel.to_a).to eq []
      end

      it "works with chaining", :aggregate_failures do
        expect(rel.none.where.not(user_id: 1, dummy: :a).to_sql)
          .to eq "select * from \"dummy\" where (time < 0) and (user_id <> 1) and (dummy <> 'a')"
        expect(rel.to_a).to eq []
      end
    end

    describe "#past" do
      it "work with predefined symbols" do
        expect(rel.past(:hour).to_sql).to eq "select * from \"dummy\" where (time > now() - 1h)"
      end

      it "work with any symbols" do
        expect(rel.past(:s).to_sql).to eq "select * from \"dummy\" where (time > now() - 1s)"
      end

      it "work with strings" do
        expect(rel.past("3d").to_sql).to eq "select * from \"dummy\" where (time > now() - 3d)"
      end

      it "work with numbers" do
        expect(rel.past(1.day).to_sql).to eq "select * from \"dummy\" where (time > now() - 86400s)"
      end
    end

    describe "#since" do
      it "work with datetime" do
        expect(rel.since(Time.utc(2014, 12, 31)).to_sql).to eq "select * from \"dummy\" where (time > 1419984000s)"
      end
    end

    describe "#group" do
      it "generate valid groups" do
        expect(rel.group(:user_id, "time(1m) fill(0)").to_sql).to eq "select * from \"dummy\" group by user_id, time(1m) fill(0)"
      end

      context "group by time predefined values" do
        it "group by hour" do
          expect(rel.time(:hour).to_sql).to eq "select * from \"dummy\" group by time(1h)"
        end

        it "group by minute" do
          expect(rel.time(:minute).to_sql).to eq "select * from \"dummy\" group by time(1m)"
        end

        it "group by second" do
          expect(rel.time(:second).to_sql).to eq "select * from \"dummy\" group by time(1s)"
        end

        it "group by millisecond" do
          expect(rel.time(:ms).to_sql).to eq "select * from \"dummy\" group by time(1ms)"
        end

        it "group by microsecond" do
          expect(rel.time(:u).to_sql).to eq "select * from \"dummy\" group by time(1u)"
        end

        it "group by day" do
          expect(rel.time(:day).to_sql).to eq "select * from \"dummy\" group by time(1d)"
        end

        it "group by week" do
          expect(rel.time(:week).to_sql).to eq "select * from \"dummy\" group by time(1w)"
        end

        it "group by month" do
          expect(rel.time(:month).to_sql).to eq "select * from \"dummy\" group by time(30d)"
        end

        it "group by year" do
          expect(rel.time(:year).to_sql).to eq "select * from \"dummy\" group by time(365d)"
        end

        it "group by hour and fill" do
          expect(rel.time(:month, fill: 0).to_sql).to eq "select * from \"dummy\" group by time(30d) fill(0)"
        end
      end

      it "group by time with string value" do
        expect(rel.time("4d").to_sql).to eq "select * from \"dummy\" group by time(4d)"
      end

      %w[null previous none].each do |val|
        it "group by time with string value and fill #{val}" do
          expect(rel.time("4d", fill: val.to_sym).to_sql).to eq "select * from \"dummy\" group by time(4d) fill(#{val})"
        end
      end

      it "group by time and other fields with fill zero" do
        expect(rel.time("4d", fill: 0).group(:dummy_id).to_sql).to eq "select * from \"dummy\" group by time(4d), dummy_id fill(0)"
      end

      it "group by time and other fields with fill negative" do
        expect(rel.time("4d", fill: -1).group(:dummy_id).to_sql).to eq "select * from \"dummy\" group by time(4d), dummy_id fill(-1)"
      end
    end

    describe "#order" do
      it "generate valid order" do
        expect(rel.order(time_spent: :asc).to_sql).to eq "select * from \"dummy\" order by time_spent asc"
      end

      it "generate order from string" do
        expect(rel.order("cpu desc, val asc").to_sql).to eq "select * from \"dummy\" order by cpu desc, val asc"
      end
    end

    describe "#limit" do
      it "generate valid limit" do
        expect(rel.limit(100).to_sql).to eq "select * from \"dummy\" limit 100"
      end
    end

    describe "#slimit" do
      it "generate valid slimit" do
        expect(rel.slimit(100).to_sql).to eq "select * from \"dummy\" slimit 100"
      end
    end

    describe "#offset" do
      it "generate valid offset" do
        expect(rel.limit(100).offset(10).to_sql).to eq "select * from \"dummy\" limit 100 offset 10"
      end
    end

    describe "#soffset" do
      it "generate valid soffset" do
        expect(rel.soffset(10).to_sql).to eq "select * from \"dummy\" soffset 10"
      end
    end

    describe "#timezone" do
      it "generate valid soffset" do
        expect(rel.soffset(10).timezone("Europe/Berlin").to_sql).to eq "select * from \"dummy\" soffset 10 TZ('Europe/Berlin')"
      end
    end

    context "calculations" do
      context "one arg calculation methods" do
        [
          :count, :min, :max, :mean,
          :mode, :median, :distinct, :derivative,
          :stddev, :sum, :first, :last
        ].each do |method|
          describe "##{method}" do
            specify do
              expect(rel.where(user_id: 1).calc(method, :column_name).to_sql)
                .to eq "select #{method}(column_name) from \"dummy\" where (user_id = 1)"
            end
          end
        end
      end

      context "with aliases" do
        it "select count as alias" do
          expect(rel.count(:val, "total").to_sql).to eq "select count(val) as total from \"dummy\""
        end

        it "select percentile as alias" do
          expect(rel.percentile(:val, 90, "p1").to_sql).to eq "select percentile(val, 90) as p1 from \"dummy\""
        end
      end
    end

    context "complex queries" do
      it "group + where" do
        expect(rel.count("user_id").group(:traffic_source).fill(0).where(user_id: 123).past("28d").to_sql)
          .to eq "select count(user_id) from \"dummy\" where (user_id = 123) and (time > now() - 28d) " \
                 "group by traffic_source fill(0)"
      end

      it "where + group + order + limit" do
        expect(rel.group(:user_id).where(account_id: 123).order(account_id: :desc).limit(10).offset(10).to_sql)
          .to eq "select * from \"dummy\" where (account_id = 123) group by user_id " \
                 "order by account_id desc limit 10 offset 10"
      end

      it "offset + slimit" do
        expect(rel.where(account_id: 123).slimit(10).offset(10).to_sql)
          .to eq "select * from \"dummy\" where (account_id = 123) " \
                 "offset 10 slimit 10"
      end

      it "offset + slimit + timezone" do
        expect(rel.where(account_id: 123).slimit(10).offset(10).timezone("Europe/Berlin").to_sql)
          .to eq "select * from \"dummy\" where (account_id = 123) " \
                 "offset 10 slimit 10 TZ('Europe/Berlin')"
      end
    end
  end

  describe "#empty?" do
    it "return false if has points" do
      allow(client).to receive(:query) { [{"values" => [{time: 1, id: 2}]}] }
      expect(rel.empty?).to be_falsey
      expect(rel.present?).to be_truthy
    end

    it "return true if no points" do
      allow(client).to receive(:query) { [] }
      expect(rel.empty?).to be_truthy
      expect(rel.present?).to be_falsey
    end
  end

  describe "#delete_all" do
    it "client expects to execute query method" do
      expected_query = "drop series from \"dummy\""

      expect(client)
        .to receive(:query).with(expected_query)

      rel.delete_all
    end

    it "without tags" do
      expect(rel.delete_all)
        .to eq "drop series from \"dummy\""
    end

    it "with tags" do
      expect(rel.where(dummy_id: 1, host: "eu").delete_all)
        .to eq "drop series from \"dummy\" where (dummy_id = '1') and (host = 'eu')"
    end

    it "with time" do
      expect(rel.where(time: Time.parse("2018-01-01T12:00:00.000Z")).delete_all)
        .to eq("delete from \"dummy\" where (time = 1514808000000000000)")
    end

    it "with time range" do
      range = Time.parse("2018-01-01T12:00:00.000Z")..Time.parse("2018-01-02T12:00:00.000Z")
      expect(rel.where(time: range).delete_all)
        .to eq("delete from \"dummy\" where (time >= 1514808000000000000 and time <= 1514894400000000000)")
    end
  end

  describe "#inspect" do
    it "return correct String represantation of empty relation" do
      allow(rel).to receive(:to_a) { [] }
      expect(rel.inspect).to eq "#<Influxer::Relation []>"
    end

    it "return correct String represantation of non-empty relation" do
      allow(rel).to receive(:to_a) { [1, 2, 3] }
      expect(rel.inspect).to eq "#<Influxer::Relation [1, 2, 3]>"
    end

    it "return correct String represantation of non-empty large (>11) relation" do
      allow(rel).to receive(:to_a) { [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] }
      expect(rel.inspect).to eq "#<Influxer::Relation [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, ...]>"
    end
  end

  describe "#epoch" do
    it "format :h" do
      expect(client).to receive(:query).with('select * from "dummy"', denormalize: true, epoch: :h).and_return []
      DummyMetrics.epoch(:h).all.to_a
    end

    it "format :m" do
      expect(client).to receive(:query).with('select * from "dummy"', denormalize: true, epoch: :m).and_return []
      DummyMetrics.epoch(:m).all.to_a
    end

    it "format :s" do
      expect(client).to receive(:query).with('select * from "dummy"', denormalize: true, epoch: :s).and_return []
      DummyMetrics.epoch(:s).all.to_a
    end

    it "format :ms" do
      expect(client).to receive(:query).with('select * from "dummy"', denormalize: true, epoch: :ms).and_return []
      DummyMetrics.epoch(:ms).all.to_a
    end

    it "format :u" do
      expect(client).to receive(:query).with('select * from "dummy"', denormalize: true, epoch: :u).and_return []
      DummyMetrics.epoch(:u).all.to_a
    end

    it "format :ns" do
      expect(client).to receive(:query).with('select * from "dummy"', denormalize: true, epoch: :ns).and_return []
      DummyMetrics.epoch(:ns).all.to_a
    end

    it "invalid epoch format" do
      expect(client).to receive(:query).with('select * from "dummy"', denormalize: true, epoch: nil).and_return []
      DummyMetrics.epoch(:invalid).all.to_a
    end
  end

  describe "#timezone" do
    it "should attach timezone call if timezone is set" do
      expect(client).to receive(:query).with('select * from "dummy" TZ(\'Europe/Berlin\')', denormalize: true, epoch: nil).and_return []
      DummyMetrics.timezone("Europe/Berlin").all.to_a
    end
  end
end
