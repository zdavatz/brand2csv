#encoding : utf-8
require 'spec_helper'

describe 'Get some simple example from swissreg' do
  
  HasVertreterPos = 4
  
  it "should get correct results from swissreg" do
    marke = 'aspectra*'
    timespan = '01.01.2012-31.12.2012'
    setup_swissreg_ch_server(marke, timespan, 'aspectra', ["P-480296", "P-482236", "641074"])
    results = nil
    capture(:stdout) { results = Brand2csv::run(timespan, marke) }
    results.should_not be_nil
    results.size.should == 3
    results[0].zeile_1.should == 'Aspectra AG'
    results[0].plz.should == '8004'
    results[0].ort.should == 'Zürich'
    csv = "#{timespan}.csv"
    csv_lines = IO.readlines(csv)
    csv_lines[1].split(';')[HasVertreterPos].should == "Ja"
    csv_lines[2].split(';')[HasVertreterPos].should == "Ja"
    csv_lines[3].split(';')[HasVertreterPos].should == "Nein"
  end

  it "should get correct results from swissreg when owner has two postal addresses" do
    marke = 'Urner Wildheu'
    timespan = '01.05.2013-30.06.2013'
    setup_swissreg_ch_server(marke, timespan, 'urner_wildheu', ["57862/2013"])    
    results = nil
    capture(:stdout) { results = Brand2csv::run(timespan, marke) }
    results.should_not be_nil
    results.size.should == 1
    results[0].zeile_1.should == 'Philipp Arnold'
    results[0].zeile_2.should == 'Seestrasse 37a'
    results[0].plz.should == '6454'
    results[0].ort.should == 'Flüelen'
    csv = "#{timespan}.csv"
    csv_lines = IO.readlines(csv)
    csv_lines[1].split(';')[2].should == 'Philipp Arnold, Seestrasse 37a, 6454 Flüelen'
    csv_lines[1].split(';')[HasVertreterPos].should == "Ja"
  end

end
