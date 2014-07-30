require 'spec_helper'


describe Testo do
  let(:testo) {  Testo.new }
  specify { expect(testo).to respond_to :metrics }  
end