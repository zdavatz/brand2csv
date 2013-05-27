require 'rspec'
require 'pp'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/','brand2csv.rb'))

include Brand2csv

describe 'Short (e.g. corvatsch*)' do
  TrademarkSearch = 'TRADEMARK REGISTER SEARCH TIMES: QUERY=[10] SELECT=[70] SERVER=[80] DELEGATE=[93] (HITS=[9])'
  before :each do
    dataDir =  File.expand_path(File.join(File.dirname(__FILE__), 'data'))
    session = Swissreg.new("01.01.1990", 'Branding')
    filename = "#{dataDir}/result_short.html"
    File.exists?(filename).should be_true
    doc = Nokogiri::Slop(File.open(filename))
    @einfach = Swissreg::Vereinfachte.new(doc)
  end
  
  it "short search must return info about trademark search" do
    Swissreg::inputValue(@einfach.inputData, 'id_swissreg:mainContent:vivian').should == TrademarkSearch
  end
  
  it "short search must return hit information" do
    @einfach.firstHit.should == 1
    @einfach.nrHits.should == 9
  end

  it "short search must return details" do
    @einfach.links2details.should_not be_nil
    @einfach.links2details.size.should == 9
    @einfach.links2details.index(901614).should_not be_nil
  end

  it "short search must return information about (sub-)pages" do
    @einfach.pageNr.should == 1
    @einfach.nrSubPages.should == 1
  end

  it "short search getPostDataForSubpage" do
    @einfach.pageNr.should == 1
    data = @einfach.getPostDataForSubpage(2)
    data.should_not be_nil
    Swissreg::inputValue(data, 'tmMainId').should == ""
    Swissreg::inputValue(data, 'id_swissreg:mainContent:scroll_1').should == "idx2"
    Swissreg::inputValue(data, 'id_swissreg:_idcl').should == 'id_swissreg:mainContent:scroll_1idx2'
  end

  it "short search getPostDataForDetail" do
    @einfach.pageNr.should == 1
    position = 3
    id = 937439
    data = @einfach.getPostDataForDetail(position, id)
    data.should_not be_nil
    Swissreg::inputValue(data, 'tmMainId').should == "#{id}"
    Swissreg::inputValue(data, 'id_swissreg:mainContent:scroll_1').should == ''
    Swissreg::inputValue(data, 'id_swissreg:_idcl').should == "id_swissreg:mainContent:data:#{position}:tm_no_detail:id_detail"
  end
end