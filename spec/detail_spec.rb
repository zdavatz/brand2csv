#encoding : utf-8
require 'rspec'
require 'pp'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/','brand2csv.rb'))

include Brand2csv

describe 'Detail' do
  before :each do
    dataDir =  File.expand_path(File.join(File.dirname(__FILE__), 'data'))
    session = Swissreg.new("01.01.1990", 'Branding')
    filename = "#{dataDir}/vereinfachte_detail_33.html"
    File.exists?(filename).should be_true
    doc = Nokogiri::Slop(File.open(filename))
    @marke = Swissreg::getMarkenInfoFromDetail(doc)
  end
  
  it "collected trademark information must be correct" do
    @marke.should_not be_nil
    @marke.zeile_1.should == "Peter Löcker Bauart"
    @marke.zeile_2.should == "Trollstrasse 20"
    @marke.zeile_3.should be_nil
    @marke.plz.should == '8400'
    @marke.ort.should == 'Winterthur'
    @marke.markennummer.should == '00135/2013'
    @marke.inhaber.should == "Peter Löcker Bauart, Trollstrasse 20, 8400 Winterthur"
    @marke.name.should == 'https://www.swissreg.ch/srclient/images/loadImage?Action=LoadImg&ItemType=tm&ImageType=print&ImageHash=F431E13A9D8F363BD06604796634142A18A5BA7C.jpeg'
  end

end