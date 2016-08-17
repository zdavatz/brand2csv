#encoding : utf-8
require 'spec_helper'

include Brand2csv

describe 'Tests for utility procedure' do
  
  before :each do
    @data = [
      ["autoScroll", ""],
      ["id_swissreg:mainContent:id_show_simple_view_hitlist", "Vereinfachte Trefferliste anzeigen"],
      ["id_swissreg_SUBMIT", "1"],
      ["id_swissreg:_idcl", "id_swissreg_sub_nav_ipiNavigation_item0"],
      ["id_swissreg:_link_hidden_", ""],
      ["javax.faces.ViewState", 'xzy' ],
    ]
  end
  
  it "inputValue should return nil for not existing key " do
    expect(Swissreg::inputValue(@data, 'xxx')).to be_nil
  end
  
  it "inputValue should return correct value for existing key " do
    expect(Swissreg::inputValue(@data, 'autoScroll')).to eq('')
    expect(Swissreg::inputValue(@data, 'id_swissreg:mainContent:id_show_simple_view_hitlist')).to eq("Vereinfachte Trefferliste anzeigen")
  end
  
  it "HitsPerPage must be 250" do
    expect(Swissreg::HitsPerPage).to eq(250)
  end
  
end

describe 'Tests parsing adress line' do
  
  it "must handle correctly Via San Salvatore, 2" do
    full_address_line = 'Ideal Hobby Sagl, Via San Salvatore, 2, 6902 Paradiso'
    number = 'for_debugging'
    zeile_1, zeile_2, zeile_3, zeile_4, zeile_5, plz, ort = Swissreg::parseAddress(number, full_address_line)
    expect(zeile_1).to eq('Ideal Hobby Sagl')
    expect(zeile_2).to eq('Via San Salvatore, 2')
    expect(zeile_3).to be_nil
    expect(plz).to eq('6902')
    expect(ort).to eq('Paradiso')
  end
  
  it "must handle correctly 90, route de Frontenex" do    
    full_address_line = 'Olivier Karim Wasem, 90, route de Frontenex, 1208 Genève'
    number = 'for_debugging'
    zeile_1, zeile_2, zeile_3, zeile_4, zeile_5, plz, ort = Swissreg::parseAddress(number, full_address_line)
    expect(zeile_1).to eq('Olivier Karim Wasem')
    expect(zeile_2).to eq('90, route de Frontenex')
    expect(zeile_3).to be_nil
    expect(plz).to eq('1208')
    expect(ort).to eq('Genève')
  end
  
  it "must handle ampersands correctly" do
    full_address_line = 'Schweiz. Serum- &amp; Impfinstitut, und Institut zur Erforschung der, Infektionskrankheiten, Rehhagstrasse 79, 3018 Bern'    
    number = 'for_debugging'
    zeile_1, zeile_2, zeile_3, zeile_4, zeile_5, plz, ort = Swissreg::parseAddress(number, full_address_line)
    expect(zeile_1).to eq('Schweiz. Serum- & Impfinstitut')
    expect(zeile_2).to eq('und Institut zur Erforschung der')
    expect(zeile_3).to eq('Infektionskrankheiten')
    expect(zeile_4).to eq('Rehhagstrasse 79')
    expect(zeile_5).to be_nil
    expect(plz).to eq('3018')
    expect(ort).to eq('Bern')
  end

  it "must handle several postal addresses correctly" do 
    full_address_line = 'Philipp Arnold, Seestrasse 37a, 6454 Flüelen, , Peter Tresoldi, c/o Xitix GmbH, Rathausplatz 4, 6460 Altdorf'
    number = 'for_debugging'
    zeile_1, zeile_2, zeile_3, zeile_4, zeile_5, plz, ort = Swissreg::parseAddress(number, full_address_line)
    expect(zeile_1).to eq('Philipp Arnold')
    expect(zeile_2).to eq('Seestrasse 37a')
    expect(zeile_3).to be_nil
    expect(zeile_4).to be_nil
    expect(zeile_5).to be_nil
    expect(plz).to eq('6454')
    expect(ort).to eq('Flüelen')
  end
end
