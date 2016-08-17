#encoding : utf-8
require 'spec_helper'
require 'tempfile'

include Brand2csv

describe 'Csv' do
  before :each do
    dataDir =  File.expand_path(File.join(File.dirname(__FILE__), 'data'))
    session = Swissreg.new("01.01.1990", 'Branding')
    filename = "#{dataDir}/vereinfachte_detail_33.html"
    File.exists?(filename).should be_true
    doc = Nokogiri::Slop(File.open(filename))
    @marke = Swissreg::getMarkenInfoFromDetail(doc)
  end
  
  it "must be able to create a correct csv file" do
    results = [@marke]
    file = Tempfile.new('foo')
    Swissreg::emitCsv(results, file.path)
    inhalte = IO.readlines(file.path)
    inhalte[0].chomp.should == 'name;markennummer;inhaber;land;hatVertreter;hinterlegungsdatum;zeile_1;zeile_2;zeile_3;zeile_4;zeile_5;plz;ort'
    inhalte[1].chomp.should == 'https://www.swissreg.ch/srclient/images/loadImage?Action=LoadImg&ItemType=tm&ImageType=print&ImageHash=F431E13A9D8F363BD06604796634142A18A5BA7C.jpeg;00135/2013;Peter Löcker Bauart, Trollstrasse 20, 8400 Winterthur;Schweiz;Nein;13.03.2013;Peter Löcker Bauart;Trollstrasse 20;;;;8400;Winterthur'
    inhalte[2].should == nil
  end

end
describe 'CSV with matching addresses' do
  before :each do
    dataDir =  File.expand_path(File.join(File.dirname(__FILE__), 'data'))
    @results = []
    session = Swissreg.new("01.01.1990", 'Branding')
    [ 'detail_00001_P-480296.html', 'detail_00002_P-482236.html'].each do |name|
      filename = "#{dataDir}/aspectra/#{name}"
      File.exists?(filename).should be_true
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
    @results[0].markennummer.should eq First_TM
    @results[0].inhaber.should eq Inhaber
    @results[1].markennummer.should eq Second_TM
    @results[1].inhaber.should eq Inhaber
    inhalte[1].split(';')[2].should eq Inhaber
    inhalte[1].split(';')[1].should eq First_TM
    inhalte[2].should be_nil
  end
end
