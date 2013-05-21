#!/usr/bin/env ruby
require 'mechanize'
require 'prettyprint'

a = Mechanize.new { |agent|
 #  agent.user_agent_alias = 'Mac Safari'
  agent.user_agent = 'Mozilla/5.0 (X11; Linux x86_64; rv:16.0) Gecko/20100101 Firefox/16.0'
#  agent.redirection_limit   = 5
  agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
}

def writeResponse(filename, body)
  ausgabe = File.open(filename, 'w+')
  ausgabe.puts body
  ausgabe.close
end
def view_state(response)
#  if match = /javax.faces.ViewState.*?value="([^"]+)"/u.match(response.body.force_encoding('utf-8'))
  if match = /javax.faces.ViewState.*?value="([^"]+)"/u.match(response.force_encoding('utf-8'))
    match[1]
  else
    ""
  end
end

$base_uri = 'https://www.swissreg.ch'
$start_uri = "#{$base_uri}/srclient/faces/jsp/start.jsp"

page = a.get $start_uri  # get a cookie for the session
pp page.links
content = a.get_file $start_uri
FileUtils.makedirs 'mechanize'
writeResponse('mechanize/main.html', content)
state = view_state(content)
pp state
data = [
  ["autoScroll", "0,0"],
  ["id_swissreg:_link_hidden_", ""],
  ["id_swissreg_SUBMIT", "1"],
  ["id_swissreg:_idcl", "id_swissreg_sub_nav_ipiNavigation_item0"],
  ["javax.faces.ViewState", state],
]

content = a.post($start_uri, data)  
writeResponse('mechanize/einfache_suche.html', content.body)

data = [
  ["autoScroll", "0,0"],
  ["id_swissreg:_link_hidden_", ""],
  ["id_swissreg_SUBMIT", "1"],
  ["id_swissreg:_idcl", "id_swissreg_sub_nav_ipiNavigation_item0_item3"],
  ["javax.faces.ViewState", state],
]
# sr1 ist die einfache suche, sr3 die erweiterte Suche
path = "/srclient/faces/jsp/trademark/sr3.jsp"
response = a.post($base_uri + path, data)
writeResponse('mechanize/erweiterte_suche.html', response.body)
# Bis hier alles okay
marke = 'asp*'
timespan = "01.06.2007-30.06.2007"  # 19.06.2007
    criteria = [
      ["autoScroll", "0,0"],
      ["id_swissreg:_link_hidden_", ""],
      # "id_swissreg:mainContent:id_cbxFormatChoice" 2 = Publikationsansicht 1 = Registeransicht
      ["id_swissreg:mainContent:id_cbxFormatChoice", "1"],
      ["id_swissreg:mainContent:id_ckbTMState", "1"], # "Hängige Gesuche 1
#      ["id_swissreg:mainContent:id_ckbTMState", "2"], # "Gelöschte Gesuche 2
      ["id_swissreg:mainContent:id_ckbTMState", "3"], # aktive Marken 3 
#      ["id_swissreg:mainContent:id_ckbTMState", "4"], # gelöschte Marken 4
      ["id_swissreg:mainContent:id_cbxCountry", "CH"], # Auswahl Länder _ALL
      ["id_swissreg:mainContent:id_txf_tm_no", ""],  # Marken Nr
      ["id_swissreg:mainContent:id_txf_app_no", ""],                       # Gesuch Nr.
      ["id_swissreg:mainContent:id_txf_tm_text", "#{marke}"],                # Wortlaut der Marke
      ["id_swissreg:mainContent:id_txf_applicant", ""],                    # Inhaber/in
      ["id_swissreg:mainContent:id_txf_agent", ""],                         # Vertreter/in
      ["id_swissreg:mainContent:id_txf_licensee", ""], # Lizenznehmer
      ["id_swissreg:mainContent:id_txf_nizza_class", ""], # Nizza Klassifikation Nr.
      ["id_swissreg:mainContent:id_txf_appDate", "#{timespan}"], # Hinterlegungsdatum
      ["id_swissreg:mainContent:id_txf_expiryDate", ""], # Ablauf Schutzfrist
      # Markenart: Individualmarke 1 Kollektivmarke 2 Garantiemarke 3
      ["id_swissreg:mainContent:id_cbxTMTypeGrp", "_ALL"],  # Markenart
      ["id_swissreg:mainContent:id_cbxTMForm", "_ALL"],  # Markentyp
      ["id_swissreg:mainContent:id_cbxTMColorClaim", "_ALL"],  # Farbanspruch
      ["id_swissreg:mainContent:id_txf_pub_date", ""], # Publikationsdatum
#      name="id_swissreg:mainContent:id_ckbTMChoice", "tm_lbl_applicant"], # />&#160;Inhaber/in</label></td>
      
    # info zu Publikationsgrund id_swissreg:mainContent:id_ckbTMPubReason
      ["id_swissreg:mainContent:id_ckbTMPubReason", "1"], #Neueintragungen
      ["id_swissreg:mainContent:id_ckbTMPubReason", "2"], #Berichtigungen
      ["id_swissreg:mainContent:id_ckbTMPubReason", "3"], #Verlängerungen
      ["id_swissreg:mainContent:id_ckbTMPubReason", "4"], #Löschungen
      ["id_swissreg:mainContent:id_ckbTMPubReason", "5"], #Inhaberänderungen
      ["id_swissreg:mainContent:id_ckbTMPubReason", "6"], #Vertreteränderungen
      ["id_swissreg:mainContent:id_ckbTMPubReason", "7"], #Lizenzänderungen
      ["id_swissreg:mainContent:id_ckbTMPubReason", "8"], #Weitere Registeränderungen
      ["id_swissreg:mainContent:id_ckbTMEmptyHits", "0"],  # Leere Trefferliste anzeigen
      
      # Angezeigte Spalten "id_swissreg:mainContent:id_ckbTMChoice"
      ["id_swissreg:mainContent:id_ckbTMChoice", "tm_lbl_tm_text"], # Marke
      # ["id_swissreg:mainContent:id_ckbTMChoice", "tm_lbl_state"], # Status
      # ["id_swissreg:mainContent:id_ckbTMChoice", "tm_lbl_nizza_class"], # Nizza Klassifikation Nr.
      # ["id_swissreg:mainContent:id_ckbTMChoice", "tm_lbl_no"], # disabled="disabled"], # Nummer
      ["id_swissreg:mainContent:id_ckbTMChoice", "tm_lbl_applicant"], # Inhaber/in
      ["id_swissreg:mainContent:id_ckbTMChoice", "tm_lbl_country"], # Land (Inhaber/in)
      # ["id_swissreg:mainContent:id_ckbTMChoice", "tm_lbl_agent"], # Vertreter/in
      # ["id_swissreg:mainContent:id_ckbTMChoice", "tm_lbl_licensee"], # Lizenznehmer/in
      ["id_swissreg:mainContent:id_ckbTMChoice", "tm_lbl_app_date"], # Hinterlegungsdatum
      # ["id_swissreg:mainContent:id_ckbTMChoice", "tm_lbl_expiry_date"], # Ablauf Schutzfrist
      # ["id_swissreg:mainContent:id_ckbTMChoice", "tm_lbl_type_grp"], # Markenart
      # ["id_swissreg:mainContent:id_ckbTMChoice", "tm_lbl_form"], # Markentyp
      # ["id_swissreg:mainContent:id_ckbTMChoice", "tm_lbl_color_claim"], # Farbanspruch
      
      ["id_swissreg:mainContent:id_cbxHitsPerPage", "100"],   # Treffer pro Seite
      ["id_swissreg:mainContent:id_ckbTMChoice", "tm_lbl_applicant"],
      ["id_swissreg:mainContent:sub_fieldset:id_submit", "suchen"],
#      ["id_swissreg:mainContent:sub_fieldset:id_reset", "0"],
      ["id_swissreg_SUBMIT", "1"],
      ["javax.faces.ViewState", state],
    ]

path = "/srclient/faces/jsp/trademark/sr3.jsp"
response = a.post($base_uri + path, criteria)
writeResponse('mechanize/resultate_1.html', response.body)
criteria<<['id_swissreg:mainContent:scroll_1idx2', 'idx2']
if false # does not work, returns to the extended search path
response = a.post($base_uri + path, criteria)
writeResponse('mechanize/resultate_2.html', response.body)
end
# To click on secon return oamSubmitForm('id_swissreg','id_swissreg:mainContent:scroll_1idx2',null,[['id_swissreg:mainContent:scroll_1','idx2']]);