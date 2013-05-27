#encoding : utf-8
require 'rspec'
require 'pp'
require 'tempfile'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/','brand2csv.rb'))

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
    inhalte[0].chomp.should == 'name;markennummer;inhaber;land;hinterlegungsdatum;zeile_1;zeile_2;zeile_3;zeile_4;zeile_5;plz;ort'
    inhalte[1].chomp.should == 'https://www.swissreg.ch/srclient/images/loadImage?Action=LoadImg&ItemType=tm&ImageType=print&ImageHash=F431E13A9D8F363BD06604796634142A18A5BA7C.jpeg;00135/2013;Peter Löcker Bauart, Trollstrasse 20, 8400 Winterthur;Schweiz;13.03.2013;Peter Löcker Bauart;Trollstrasse 20;;;;8400;Winterthur'
    inhalte[2].should == nil
  end

end