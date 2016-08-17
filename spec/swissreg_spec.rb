#encoding : utf-8
require 'spec_helper'

describe 'Get some simple example from swissreg' do

  HasVertreterPos = 4
  pending ('mocking swissreg no longer works')
  if false
  it "should get correct results from swissreg" do
    marke = 'aspectra*'
    timespan = '01.01.2012-31.12.2012'
    setup_swissreg_ch_server(marke, timespan, 'aspectra', ["P-480296", "P-482236", "641074"])
    results = nil
    capture(:stdout) { results = Brand2csv::run(timespan, marke) }
    expect(results).not_to be_nil
    expect(results.size).to eq(3)
    expect(results[0].zeile_1).to eq('Aspectra AG')
    expect(results[0].plz).to eq('8004')
    expect(results[0].ort).to eq('Zürich')
    csv = "#{timespan}.csv"
    csv_lines = IO.readlines(csv)
    expect(csv_lines[1].split(';')[HasVertreterPos]).to eq("Ja")
    expect(csv_lines[2].split(';')[HasVertreterPos]).to eq("Ja")
    expect(csv_lines[3].split(';')[HasVertreterPos]).to eq("Nein")
  end

  it "should get correct results from swissreg when owner has two postal addresses" do
    marke = 'Urner Wildheu'
    timespan = '01.05.2013-30.06.2013'
    setup_swissreg_ch_server(marke, timespan, 'urner_wildheu', ["57862/2013"])
    results = nil
    capture(:stdout) { results = Brand2csv::run(timespan, marke) }
    expect(results).not_to be_nil
    expect(results.size).to eq(1)
    expect(results[0].zeile_1).to eq('Philipp Arnold')
    expect(results[0].zeile_2).to eq('Seestrasse 37a')
    expect(results[0].plz).to eq('6454')
    expect(results[0].ort).to eq('Flüelen')
    csv = "#{timespan}.csv"
    csv_lines = IO.readlines(csv)
    expect(csv_lines[1].split(';')[2]).to eq('Philipp Arnold, Seestrasse 37a, 6454 Flüelen')
    expect(csv_lines[1].split(';')[HasVertreterPos]).to eq("Ja")
  end
  end
end
