#!/usr/bin/env ruby
require 'mechanize'
require 'prettyprint'
require 'optparse'

Useage = "Usage: #{File.basename(__FILE__)} timespan
    Find all brands registered in switzerland during the given timespan.
    The following examples valid timespan periods:
      1.10.2005
      1.10.2005-31.10.2005
      1.10.2005, 5.10.2005-31.10.2005
"
OptionParser.new do |opts|
  opts.banner = Useage
  opts.on("-h", "--help", "Show this help") do |v|
    puts opts
    exit
  end
end.parse!
unless ARGV
  puts Useage
  exit 1
end

timespan = ARGV[0] 

module Brand2csv do
      # Weitere gesehene Fehler
    bekannteFehler = 
        ['Das Datum ist ung', # ültig'
          'Es wurden keine Daten gefunden.',
          'Die Suchkriterien sind teilweise unzul', # ässig',
          'Geben Sie mindestens ein Suchkriterium ein',
          'Die Suche wurde abgebrochen, da die maximale Suchzeit von 60 Sekunden',
        ]
end
$base_uri = 'https://www.swissreg.ch'
$start_uri = "#{$base_uri}/srclient/faces/jsp/start.jsp"
  
def writeResponse(filename, body)
  ausgabe = File.open(filename, 'w+')
  ausgabe.puts body
  ausgabe.close
end

def view_state(response)
  if match = /javax.faces.ViewState.*?value="([^"]+)"/u.match(response.force_encoding('utf-8'))
    match[1]
  else
    ""
  end
end

def parse_swissreg(timespan = "01.06.2007-10.06.2007",  # sollte 377 Treffer ergeben, für 01.06.2007-10.06.2007, 559271 wurde in diesem Zeitraum registriert
                   marke = nil,    
                   nummer =nil) #  nummer = "559271" ergibt genau einen treffer

  a = Mechanize.new { |agent|
  #  agent.user_agent_alias = 'Mac Safari'
    agent.user_agent = 'Mozilla/5.0 (X11; Linux x86_64; rv:16.0) Gecko/20100101 Firefox/16.0'
  #  agent.redirection_limit   = 5
    agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
  }

page = a.get $start_uri  # get a cookie for the session
content = a.get_file $start_uri
FileUtils.makedirs 'mechanize'
writeResponse('mechanize/main.html', content)
state = view_state(content)
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
#      ["id_swissreg:mainContent:id_txf_tm_no", ""],  # Marken Nr
      ["id_swissreg:mainContent:id_txf_app_no", ""],                       # Gesuch Nr.
      ["id_swissreg:mainContent:id_txf_applicant", ""],                    # Inhaber/in
      ["id_swissreg:mainContent:id_txf_agent", ""],                         # Vertreter/in
      ["id_swissreg:mainContent:id_txf_licensee", ""], # Lizenznehmer
      ["id_swissreg:mainContent:id_txf_nizza_class", ""], # Nizza Klassifikation Nr.
#      ["id_swissreg:mainContent:id_txf_appDate", timespan], # Hinterlegungsdatum
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
    if marke               # Wortlaut der Marke
      puts "Marke ist #{marke}"
     criteria << ["id_swissreg:mainContent:id_txf_tm_text", marke]
    else
      puts "Keine Marke spezifiziert. #{marke.inspect}"
     criteria << ["id_swissreg:mainContent:id_txf_tm_text", ""]
    end
    if timespan               # Hinterlegungsdatum
      puts "Hinterlegungsdatum ist #{timespan}"
      criteria << ["id_swissreg:mainContent:id_txf_appDate", timespan] # Hinterlegungsdatum
    else
      puts "Keine Hinterlegungsdatum spezifiziert. #{timespan.inspect}"
      criteria << ["id_swissreg:mainContent:id_txf_appDate", ""] # Hinterlegungsdatum
    end
    if nummer               
      puts "nummer ist #{timespan}"
      criteria << ["id_swissreg:mainContent:id_txf_tm_no", nummer] 
    else
      puts "Keine nummer spezifiziert. #{timespan.inspect}"
      criteria << ["id_swissreg:mainContent:id_txf_tm_no", ""] 
    end
    
path = "/srclient/faces/jsp/trademark/sr3.jsp"
response = a.post($base_uri + path, criteria)
writeResponse('mechanize/resultate_1.html', response.body)
criteria<<['id_swissreg:mainContent:scroll_1idx2', 'idx2']
if false # does not work, returns to the extended search path
response = a.post($base_uri + path, criteria)
writeResponse('mechanize/resultate_2.html', response.body)
end

if false # Will try later
path = "/srclient/faces/jsp/trademark/sr3.jsp"
data_detail = [
  ["autoScroll", "0,0"],
  ["id_swissreg:_link_hidden_", ""],
  ["id_swissreg_SUBMIT", "1"],
  ["id_swissreg:_idcl", "id_swissreg_sub_nav_ipiNavigation_item0_item3"],
  ["javax.faces.ViewState", state],
]

response = a.post($base_uri + path, data_detail)
https://www.swissreg.ch/srclient/faces/jsp/trademark/sr30.jsp
end
end # 
# parse_swissreg("01.06.2007-10.06.2007" , 'asp*')
require 'csv'
$results = []
$errors  = Hash.new

class Marke < Struct.new(:name, :markennummer, :inhaber, :land, :hinterlegungsdatum, :zeile_1, :zeile_2, :zeile_3, :zeile_4, :plz, :ort)
end

AddressRegexp = /^(\d\d\d\d)\W*(.*)/
LineSplit     = ', '
DefaultCountry = 'Schweiz'

def parseAddress(nummer, inhaber)
  zeile_1, zeile_2, zeile_3, zeile_4, zeile_5, zeile_6 = inhaber.split(LineSplit)
  ort = nil
  plz = nil
  if    m = AddressRegexp.match(zeile_2)
    zeile_2 = nil
    plz = m[1]; ort = m[2]
  elsif m = AddressRegexp.match(zeile_3)
    zeile_3 = nil
    plz = m[1]; ort = m[2]
  elsif m = AddressRegexp.match(zeile_4)
    zeile_4 = nil
    plz = m[1]; ort = m[2]
  elsif m = AddressRegexp.match(zeile_5)
    zeile_5 = nil
    plz = m[1]; ort = m[2]
  else
    puts "Achtung! Konnte Marke #{nummer} mit Inhaber #{inhaber} nicht parsen" if $VERBOSE
    return nil,   nil,     nil,     nil,     nil,     nil,     nil, nil
  end
  return zeile_1, zeile_2, zeile_3, zeile_4, zeile_5, zeile_6, plz, ort
end

def fetchDetails(nummer) # takes a long time!
  doc = nil
  filename = "mechanize/detail_#{nummer}.html"
  unless File.exists?(filename)
    url = "https://www.swissreg.ch/srclient/faces/jsp/trademark/sr300.jsp?language=de&section=tm&id=#{nummer}"
    a = Mechanize.new { |agent|
      #  agent.user_agent_alias = 'Mac Safari'
        agent.user_agent = 'Mozilla/5.0 (X11; Linux x86_64; rv:16.0) Gecko/20100101 Firefox/16.0'
      #  agent.redirection_limit   = 5
        agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
      }
    page = a.get $start_uri  # get a cookie for the session
    content = a.get_file url
    writeResponse("mechanize/detail_#{nummer}.html", content)
  end
  doc = Nokogiri::Slop(File.open(filename))
  path_name = "//html/body/form/div/div/fieldset/div/table/tbody/tr/td"
  elem = doc.xpath(path_name).first
  counter = 0
  doc.xpath(path_name).each{ 
    |td|
      pp "#{counter}: #{td.text}" if $VERBOSE
      counter += 1
      next unless /^inhaber/i.match(td.text)
      zeilen = []
      doc.xpath(path_name)[counter].children.each{ |child| zeilen << child.text.gsub(LineSplit,'. ') unless child.text.length == 0 } # avoid adding <br>
      if info = $errors[nummer]
        info.inhaber = zeilen.join(LineSplit)
        info.zeile_1, info.zeile_2, info.zeile_3, info.zeile_4, zeile_5, zeile_6, info.plz, info.ort = parseAddress(nummer, info.inhaber)
        $results << info
      else
        bezeichnung =  doc.xpath(path_name)[15]
        inhaber = zeilen.join(LineSplit)
        zeile_1, zeile_2, zeile_3, zeile_4, zeile_5, zeile_6, plz, ort = parseAddress(nummer, inhaber)
        hinterlegungsdatum = doc.xpath(path_name)[7]
        marke = Marke.new(bezeichnung, nummer,  inhaber,  DefaultCountry,  hinterlegungsdatum, zeile_1, zeile_2, zeile_3, zeile_4, plz, ort )
        $results << marke
      end
  }
end

def fetchresult(filename= 'mechanize/resultate_1.html')
  nrFailures = 0
  # doc = Nokogiri::Slop(inhalt) 
  doc = Nokogiri::Slop(File.open(filename))
  path_name = "//html/body/form/div/div/fieldset/table/tbody/tr/td/table/tbody/tr"
  elem = doc.xpath(path_name).first
  doc.xpath(path_name).each{ 
    |elem|
    bezeichnung = elem.elements[1].text
    land = elem.elements[4].text
    next unless /#{DefaultCountry}/i.match(land)
    inhaber =  elem.elements[3].text
    nummer  = elem.elements[2].text
    if bezeichnung.length == 0
      bezeichnung = elem.children[1].children[0].children[0].children[0].attribute('src').to_s
    end
    zeile_1, zeile_2, zeile_3, zeile_4, zeile_5, zeile_6, plz, ort = parseAddress(nummer, inhaber)
    if zeile_1
      $results << Marke.new(bezeichnung, elem.elements[2].text,  elem.elements[3].text,  land,  elem.elements[5].text,
                            zeile_1, zeile_2, zeile_3, zeile_4, plz, ort )
    else
      nrFailures += 1
      $errors[nummer] = Marke.new(bezeichnung, elem.elements[2].text,  elem.elements[3].text,  land,  elem.elements[5].text,
                            zeile_1, zeile_2, zeile_3, zeile_4, plz, ort )
    end
  }
  puts "Es gab #{nrFailures} Fehler beim lesen von #{filename}"  if $VERBOSE
end

pp 1
parse_swissreg(timespan)
pp 2
fetchresult
$errors.each{ 
  |markennummer, info|
    fetchDetails(markennummer) 
}

CSV.open('ausgabe.csv', 'w') do |csv|
  $results.each{ |x| csv << x }
end
