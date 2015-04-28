require 'spec_helper'

describe Testo do
  let(:testo) {  Testo.new receipt_id: 10 }
  specify { expect(testo).to respond_to :metrics }
  specify { expect(testo).to respond_to :testo_metrics }
  specify { expect(testo).to respond_to :testo2_metrics }
  specify { expect(testo).to respond_to :custom_metrics }

  describe "metrics attributes" do
    it "should add foreign key and inherits" do
      expect(testo.metrics.build.testo_id).to eq testo.id
      expect(testo.testo_metrics.build.testo_id).to eq testo.id
      expect(testo.testo_metrics.build.receipt_id).to eq 10
    end

    it "should add custom foreign key" do
      expect(testo.testo2_metrics.build.testo).to eq testo.id
    end

    it "should add nil foreign key" do
      expect(testo.custom_metrics.build.testo_id).to be_nil
      expect(testo.custom_metrics.build.testo).to be_nil
      expect(testo.custom_metrics.build.receipt_id).to be_nil
    end
  end
end
