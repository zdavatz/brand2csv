#encoding : utf-8
require 'spec_helper'

include Brand2csv

describe 'Get some simple example from swissreg' do
  before { setup_swissreg_ch_server }

  it "should get correct results from swissreg" do
    marke = 'aspectra*'
    timespan = '01.01.2012-31.12.2012'
    markierung = "Marke=#{marke}; Hinterlegungsdatum=#{timespan}; Markenart=Alle; Markentyp=Alle; Farbanspruch=Alle; Publikationsgrund= Neueintragungen, Berichtigungen; Status= hängige Gesuche, aktive Marken"
    results = Brand2csv::run(timespan, marke)
    results.should_not be_nil
    results.size.should == 2
    results[0].zeile_1.should == 'Aspectra AG'
    results[0].plz.should == '8004'
    results[0].ort.should == 'Zürich'
  end
end
