require 'spec_helper'

include Brand2csv

describe 'trademark number search' do
  
  before :each do
    dataDir =  File.expand_path(File.join(File.dirname(__FILE__), 'data'))
    filename = "#{dataDir}/result_short.html"
    expect(File.exists?(filename)).to be_truthy
    @doc = Nokogiri::Slop(File.open(filename))
  end
  
  it "trademark number search must contain 9 numbers" do
    numbers = Swissreg::getTrademarkNumbers(@doc)
    expect(numbers).not_to be_nil
    expect(numbers.size).to eq(9)
    expect(numbers.index('00127/2011')).not_to be_nil
  end

end
