#!/usr/bin/env ruby
# encoding: utf-8
require 'rubygems' if /^1\.8/.match(RUBY_VERSION)
require 'mechanize'
require 'prettyprint'

def writeResponse(filename)
  ausgabe = File.open(filename, 'w+')
  ausgabe.puts @agent.page.body
  ausgabe.close
end

@agent = Mechanize.new { |agent|
  agent.user_agent = 'Mozilla/5.0 (X11; Linux x86_64; rv:16.0) Gecko/20100101 Firefox/16.0'
  agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
}

@agent.get_file 'https://www.swissreg.ch/srclient/faces/jsp/start.jsp'
writeResponse("log_#{__LINE__}.html") # complains about missing 
@agent.page.links[3].click
writeResponse("log_#{__LINE__}.html")
@state = @agent.page.form["javax.faces.ViewState"]
data = [
  ["autoScroll", "0,0"],
  ["id_swissreg:_link_hidden_", ""],
  ["id_swissreg_SUBMIT", "1"],
  ["id_swissreg:_idcl", "id_swissreg_sub_nav_ipiNavigation_item0"],
  ["javax.faces.ViewState", @state],
]
@agent.page.form['id_swissreg:_idcl'] = 'id_swissreg_sub_nav_ipiNavigation_item0'
@agent.page.forms.first.submit
writeResponse("log_#{__LINE__}.html")
data = [
  ["autoScroll", "0,0"],
  ["id_swissreg:_link_hidden_", ""],
  ["id_swissreg_SUBMIT", "1"],
  ["id_swissreg:_idcl", "id_swissreg_sub_nav_ipiNavigation_item0_item3"],
  ["javax.faces.ViewState", @state],
]
@agent.page.form['id_swissreg:_idcl'] = 'id_swissreg_sub_nav_ipiNavigation_item0_item3'
@agent.page.forms.first.submit
writeResponse("log_#{__LINE__}.html")
data = [
["autoScroll", "0,829"],
["id_swissreg:_link_hidden_", ""],
["id_swissreg:mainContent:id_ckbTMState", "1"], # "Hängige Gesuche 1
["id_swissreg:mainContent:id_ckbTMState", "3"], # "Hängige Gesuche 1
["id_swissreg:mainContent:id_txf_tm_no", ""],# Marken Nr
["id_swissreg:mainContent:id_txf_app_no", ""],                       # Gesuch Nr.
["id_swissreg:mainContent:id_txf_tm_text", "asp*"],
["id_swissreg:mainContent:id_txf_applicant", ""],                    # Inhaber/in
["id_swissreg:mainContent:id_txf_agent", ""],                         # Vertreter/in
["id_swissreg:mainContent:id_txf_licensee", ""], # Lizenznehmer
["id_swissreg:mainContent:id_txf_nizza_class", ""], # Nizza Klassifikation Nr.
["id_swissreg:mainContent:id_txf_appDate", "01.01.2000-31.12.2012"] ,
["id_swissreg:mainContent:id_txf_expiryDate", ""], # Ablauf Schutzfrist
["id_swissreg:mainContent:id_cbxTMTypeGrp", "_ALL"],  # Markenart
["id_swissreg:mainContent:id_cbxTMForm", "_ALL"],  # Markentyp
["id_swissreg:mainContent:id_cbxTMColorClaim", "_ALL"],  # Farbanspruch
["id_swissreg:mainContent:id_txf_pub_date", ""], # Publikationsdatum
["id_swissreg:mainContent:id_ckbTMPubReason", '1'],
["id_swissreg:mainContent:id_ckbTMPubReason", '2'],
["id_swissreg:mainContent:id_cbxFormatChoice", "1"],
["id_swissreg:mainContent:id_ckbTMChoice", "tm_lbl_tm_text"],
["id_swissreg:mainContent:id_ckbTMChoice", "tm_lbl_applicant"],
["id_swissreg:mainContent:id_ckbTMChoice", "tm_lbl_country"],
["id_swissreg:mainContent:id_cbxHitsPerPage", 250],   # Treffer pro Seite
["id_swissreg:mainContent:sub_fieldset:id_submit", "suchen"],
["id_swissreg_SUBMIT", "1"],
["id_swissreg:_idcl", ""],
["id_swissreg:_link_hidden_", ""],
["javax.faces.ViewState", @state],
]
@agent.post('https://www.swissreg.ch/srclient/faces/jsp/trademark/sr3.jsp', data)  
writeResponse("log_#{__LINE__}.html")
