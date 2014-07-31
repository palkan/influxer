require 'spec_helper'


describe Testo do
  let(:testo) {  Testo.new receipt_id: 10}
  specify { expect(testo).to respond_to :metrics } 
  specify { expect(testo).to respond_to :testo_metrics }  

  describe "metrics attributes" do

    it "should add foreign key and inherits" do
      expect(testo.metrics.build.testo_id).to eq testo.id
      expect(testo.testo_metrics.build.testo_id).to eq testo.id
      expect(testo.testo_metrics.build.receipt_id).to eq 10
    end

  end
end