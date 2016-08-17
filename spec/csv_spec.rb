#encoding : utf-8
require 'spec_helper'
require 'tempfile'

include Brand2csv

describe 'Csv' do
  before :each do
    dataDir =  File.expand_path(File.join(File.dirname(__FILE__), 'data'))
    session = Swissreg.new("01.01.1990", 'Branding')
    filename = "#{dataDir}/vereinfachte_detail_33.html"
    expect(File.exists?(filename)).to be_truthy
    doc = Nokogiri::Slop(File.open(filename))
    @marke = Swissreg::getMarkenInfoFromDetail(doc)
  end
  
  it "must be able to create a correct csv file" do
    results = [@marke]
    file = Tempfile.new('foo')
    Swissreg::emitCsv(results, file.path)
    inhalte = IO.readlines(file.path)
    expect(inhalte[0].chomp).to eq('name;markennummer;inhaber;land;hatVertreter;hinterlegungsdatum;zeile_1;zeile_2;zeile_3;zeile_4;zeile_5;plz;ort')
    expect(inhalte[1].chomp).to eq('https://www.swissreg.ch/srclient/images/loadImage?Action=LoadImg&ItemType=tm&ImageType=print&ImageHash=F431E13A9D8F363BD06604796634142A18A5BA7C.jpeg;00135/2013;Peter Löcker Bauart, Trollstrasse 20, 8400 Winterthur;Schweiz;Nein;13.03.2013;Peter Löcker Bauart;Trollstrasse 20;;;;8400;Winterthur')
    expect(inhalte[2]).to eq(nil)
  end

end
describe 'CSV with matching addresses' do
  before :each do
    dataDir =  File.expand_path(File.join(File.dirname(__FILE__), 'data'))
    @results = []
    session = Swissreg.new("01.01.1990", 'Branding')
    [ 'detail_00001_P-480296.html', 'detail_00002_P-482236.html'].each do |name|
      filename = "#{dataDir}/aspectra/#{name}"
      expect(File.exists?(filename)).to be_truthy
      doc = Nokogiri::Slop(File.open(filename))
      @results << Swissreg::getMarkenInfoFromDetail(doc)
    end
  end

  Inhaber = 'Aspectra AG, Weberstrasse 4, 8004 Zürich'
  First_TM = '08326/2000'
  Second_TM = '10702/2000'

  it "must create a csv file with only one address" do
    file = Tempfile.new('foo_aspectr')
    Swissreg::emitCsv(@results, file.path)
    inhalte = IO.readlines(file.path)
    expect(@results[0].markennummer).to eq First_TM
    expect(@results[0].inhaber).to eq Inhaber
    expect(@results[1].markennummer).to eq Second_TM
    expect(@results[1].inhaber).to eq Inhaber
    expect(inhalte[1].split(';')[2]).to eq Inhaber
    expect(inhalte[1].split(';')[1]).to eq First_TM
    expect(inhalte[2]).to be_nil
  end
end
