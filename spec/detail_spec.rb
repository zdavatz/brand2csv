#encoding : utf-8
require 'spec_helper'

include Brand2csv

describe 'Detail' do
  before :each do
    dataDir =  File.expand_path(File.join(File.dirname(__FILE__), 'data'))
    session = Swissreg.new("01.01.1990", 'Branding')
    filename = "#{dataDir}/vereinfachte_detail_33.html"
    expect(File.exists?(filename)).to be_truthy
    doc = Nokogiri::Slop(File.open(filename))
    @marke = Swissreg::getMarkenInfoFromDetail(doc)
  end
  
  it "collected trademark information must be correct" do
    expect(@marke).not_to be_nil
    expect(@marke.zeile_1).to eq("Peter Löcker Bauart")
    expect(@marke.zeile_2).to eq("Trollstrasse 20")
    expect(@marke.zeile_3).to be_nil
    expect(@marke.plz).to eq('8400')
    expect(@marke.ort).to eq('Winterthur')
    expect(@marke.markennummer).to eq('00135/2013')
    expect(@marke.inhaber).to eq("Peter Löcker Bauart, Trollstrasse 20, 8400 Winterthur")
    expect(@marke.name).to eq('https://www.swissreg.ch/srclient/images/loadImage?Action=LoadImg&ItemType=tm&ImageType=print&ImageHash=F431E13A9D8F363BD06604796634142A18A5BA7C.jpeg')
  end

end
