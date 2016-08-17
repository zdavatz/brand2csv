require 'spec_helper'

include Brand2csv

describe 'Short (e.g. corvatsch*)' do
  TrademarkSearch = 'TRADEMARK REGISTER SEARCH TIMES: QUERY=[10] SELECT=[70] SERVER=[80] DELEGATE=[93] (HITS=[9])'
  before :each do
    dataDir =  File.expand_path(File.join(File.dirname(__FILE__), 'data'))
    session = Swissreg.new("01.01.1990", 'Branding')
    filename = "#{dataDir}/result_short.html"
    expect(File.exists?(filename)).to be_truthy
    doc = Nokogiri::Slop(File.open(filename))
    @einfach = Swissreg::Vereinfachte.new(doc)
  end
  
  it "short search must return info about trademark search" do
    expect(Swissreg::inputValue(@einfach.inputData, 'id_swissreg:mainContent:vivian')).to eq(TrademarkSearch)
  end
  
  it "short search must return hit information" do
    expect(@einfach.firstHit).to eq(1)
    expect(@einfach.nrHits).to eq(9)
  end

  it "short search must return details" do
    expect(@einfach.links2details).not_to be_nil
    expect(@einfach.links2details.size).to eq(9)
    expect(@einfach.links2details.index(901614)).not_to be_nil
  end

  it "short search must return information about (sub-)pages" do
    expect(@einfach.pageNr).to eq(1)
    expect(@einfach.nrSubPages).to eq(1)
  end

  it "short search getPostDataForSubpage" do
    expect(@einfach.pageNr).to eq(1)
    data = @einfach.getPostDataForSubpage(2)
    expect(data).not_to be_nil
    expect(Swissreg::inputValue(data, 'tmMainId')).to eq("")
    expect(Swissreg::inputValue(data, 'id_swissreg:mainContent:scroll_1')).to eq("idx2")
    expect(Swissreg::inputValue(data, 'id_swissreg:_idcl')).to eq('id_swissreg:mainContent:scroll_1idx2')
  end

  it "short search getPostDataForDetail" do
    expect(@einfach.pageNr).to eq(1)
    position = 3
    id = 937439
    data = @einfach.getPostDataForDetail(position, id)
    expect(data).not_to be_nil
    expect(Swissreg::inputValue(data, 'tmMainId')).to eq("#{id}")
    expect(Swissreg::inputValue(data, 'id_swissreg:mainContent:scroll_1')).to eq('')
    expect(Swissreg::inputValue(data, 'id_swissreg:_idcl')).to eq("id_swissreg:mainContent:data:#{position}:tm_no_detail:id_detail")
  end
end
