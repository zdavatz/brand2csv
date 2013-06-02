#encoding : utf-8
require 'rspec'
require 'pp'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/','brand2csv.rb'))

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
    Swissreg::inputValue(@data, 'xxx').should be_nil
  end
  
  it "inputValue should return correct value for existing key " do
    Swissreg::inputValue(@data, 'autoScroll').should == ''
    Swissreg::inputValue(@data, 'id_swissreg:mainContent:id_show_simple_view_hitlist').should == "Vereinfachte Trefferliste anzeigen"
  end
  
  it "HitsPerPage must be 250" do
    Swissreg::HitsPerPage.should == 250
  end
  
end

describe 'Tests parsing adress line' do
  
  it "must handle correctly Via San Salvatore, 2" do
    full_address_line = 'Ideal Hobby Sagl, Via San Salvatore, 2, 6902 Paradiso'
    number = 'for_debugging'
    zeile_1, zeile_2, zeile_3, zeile_4, zeile_5, plz, ort = Swissreg::parseAddress(number, full_address_line)
    zeile_1.should == 'Ideal Hobby Sagl'
    zeile_2.should == 'Via San Salvatore, 2'
    zeile_3.should be_nil
    plz.should == '6902'
    ort.should == 'Paradiso'
  end
  
  it "must handle correctly 90, route de Frontenex" do    
    full_address_line = 'Olivier Karim Wasem, 90, route de Frontenex, 1208 Genève'
    number = 'for_debugging'
    zeile_1, zeile_2, zeile_3, zeile_4, zeile_5, plz, ort = Swissreg::parseAddress(number, full_address_line)
    zeile_1.should == 'Olivier Karim Wasem'
    zeile_2.should == '90, route de Frontenex'
    zeile_3.should be_nil
    plz.should == '1208'
    ort.should == 'Genève'
  end
  
  it "must handle ampersands correctly" do
    full_address_line = 'Schweiz. Serum- &amp; Impfinstitut, und Institut zur Erforschung der, Infektionskrankheiten, Rehhagstrasse 79, 3018 Bern'    
    number = 'for_debugging'
    zeile_1, zeile_2, zeile_3, zeile_4, zeile_5, plz, ort = Swissreg::parseAddress(number, full_address_line)
    zeile_1.should == 'Schweiz. Serum- & Impfinstitut'
    zeile_2.should == 'und Institut zur Erforschung der'
    zeile_3.should == 'Infektionskrankheiten'
    zeile_4.should == 'Rehhagstrasse 79'
    zeile_5.should be_nil
    plz.should == '3018'
    ort.should == 'Bern'
  end
end