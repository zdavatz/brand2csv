require 'spec_helper'

include Brand2csv

describe 'simple search with > 500 results' do
  TrademarkSearch = 'TRADEMARK REGISTER SEARCH TIMES: QUERY=[530] SELECT=[1456] SERVER=[1991] DELEGATE=[2088] (HITS=[6349])'
  
  before :each do
    dataDir =  File.expand_path(File.join(File.dirname(__FILE__), 'data'))
    session = Swissreg.new("01.01.1990", 'Branding')
    filename = "#{dataDir}/vereinfachte_1.html"
    File.exists?(filename).should be_true
    doc = Nokogiri::Slop(File.open(filename))
    @einfach = Swissreg::Vereinfachte.new(doc)
  end
  
  it "simple search must contain inputData with vivian" do
    data = @einfach.inputData
    data.class.should == Array
    data.size.should == 9
  end

  it "simple search must return info about trademark search" do
    Swissreg::inputValue(@einfach.inputData, 'id_swissreg:mainContent:vivian').should == TrademarkSearch
  end
  
  it "simple search must return hit information" do
    @einfach.firstHit.should == 1
    @einfach.nrHits.should == 6349
  end

  it "simple search must return details" do
    @einfach.links2details.should_not be_nil
    @einfach.links2details.size.should == 250
    @einfach.links2details.index(940377).should_not be_nil
  end

  it "simple search must return information about (sub-)pages" do
    @einfach.pageNr.should == 1
    @einfach.nrSubPages.should == 26
  end

end
