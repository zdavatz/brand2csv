require 'spec_helper'

include Brand2csv

describe 'trademark number search' do
  
  before :each do
    dataDir =  File.expand_path(File.join(File.dirname(__FILE__), 'data'))
    filename = "#{dataDir}/result_short.html"
    File.exists?(filename).should be_true
    @doc = Nokogiri::Slop(File.open(filename))
  end
  
  it "trademark number search must contain 9 numbers" do
    numbers = Swissreg::getTrademarkNumbers(@doc)
    numbers.should_not be_nil
    numbers.size.should == 9
    numbers.index('00127/2011').should_not be_nil
  end

end
