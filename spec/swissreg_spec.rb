#encoding : utf-8
require 'rspec'
require 'pp'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/','brand2csv.rb'))

include Brand2csv

describe 'Get some simple example from swissreg' do

  it "should get correct results from swissreg" do
    marke = 'aspectra*'
    timespan = '01.01.2000-31.12.2012'
    markierung = "Marke=#{marke}; Hinterlegungsdatum=#{timespan}; Markenart=Alle; Markentyp=Alle; Farbanspruch=Alle; Publikationsgrund= Neueintragungen, Berichtigungen; Status= hängige Gesuche, aktive Marken"
    results = Brand2csv::run(timespan, marke)
    results.should_not be_nil
    results.size.should == 1
    results[0].zeile_1.should == 'Aspectra AG'
    results[0].plz.should == '8004'
    results[0].ort.should == 'Zürich'
  end
end
