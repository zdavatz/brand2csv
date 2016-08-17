require 'spec_helper'

include Brand2csv

describe 'simple search with > 500 results' do
  TrademarkSearch = 'TRADEMARK REGISTER SEARCH TIMES: QUERY=[530] SELECT=[1456] SERVER=[1991] DELEGATE=[2088] (HITS=[6349])'
  
  before :each do
    dataDir =  File.expand_path(File.join(File.dirname(__FILE__), 'data'))
    session = Swissreg.new("01.01.1990", 'Branding')
    filename = "#{dataDir}/vereinfachte_1.html"
    expect(File.exists?(filename)).to be_truthy
    doc = Nokogiri::Slop(File.open(filename))
    @einfach = Swissreg::Vereinfachte.new(doc)
  end
  
  it "simple search must contain inputData with vivian" do
    data = @einfach.inputData
    expect(data.class).to eq(Array)
    expect(data.size).to eq(9)
  end

  it "simple search must return info about trademark search" do
    expect(Swissreg::inputValue(@einfach.inputData, 'id_swissreg:mainContent:vivian')).to eq(TrademarkSearch)
  end
  
  it "simple search must return hit information" do
    expect(@einfach.firstHit).to eq(1)
    expect(@einfach.nrHits).to eq(6349)
  end

  it "simple search must return details" do
    expect(@einfach.links2details).not_to be_nil
    expect(@einfach.links2details.size).to eq(250)
    expect(@einfach.links2details.index(940377)).not_to be_nil
  end

  it "simple search must return information about (sub-)pages" do
    expect(@einfach.pageNr).to eq(1)
    expect(@einfach.nrSubPages).to eq(26)
  end

end
