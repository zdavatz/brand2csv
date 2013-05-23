#!/usr/bin/env ruby
# encoding: utf-8
require 'rubygems' if /^1\.8/.match(RUBY_VERSION)
require "brand2csv/version"
require 'mechanize'
require 'prettyprint'
require 'optparse'
require 'csv'
require 'logger'

module Brand2csv

  class Marke < Struct.new(:name, :markennummer, :inhaber, :land, :hinterlegungsdatum, :zeile_1, :zeile_2, :zeile_3, :zeile_4, :zeile_5, :plz, :ort)
  end

  class Swissreg
    
      # Weitere gesehene Fehler
    BekannteFehler = 
          ['Das Datum ist ung', # ültig'
           'Vereinfachte Trefferliste anzeigen',
            'Es wurden keine Daten gefunden.',
            'Die Suchkriterien sind teilweise unzul', # ässig',
            'Geben Sie mindestens ein Suchkriterium ein',
            'Die Suche wurde abgebrochen, da die maximale Suchzeit von 60 Sekunden',
           'Erweiterte Suche',
          ]
    Base_uri = 'https://www.swissreg.ch'
    Start_uri = "#{Base_uri}/srclient/faces/jsp/start.jsp"
    AddressRegexp = /^(\d\d\d\d)\W*(.*)/
    LineSplit     = ', '
    DefaultCountry = 'Schweiz'
    # Angezeigte Spalten "id_swissreg:mainContent:id_ckbTMChoice"
    TMChoiceFields = [ 
            "tm_lbl_tm_text", # Marke
            # "tm_lbl_state"], # Status
            # "tm_lbl_nizza_class"], # Nizza Klassifikation Nr.
            # "tm_lbl_no"], # disabled="disabled"], # Nummer
            "tm_lbl_applicant", # Inhaber/in
            "tm_lbl_country", # Land (Inhaber/in)
            # "tm_lbl_agent", # Vertreter/in
            # "tm_lbl_licensee"], # Lizenznehmer/in
            "tm_lbl_app_date", # Hinterlegungsdatum
            ]
    # Alle Felder mit sprechenden Namen
    # ["id_swissreg:mainContent:id_txf_tm_no", nummer],# Marken Nr
    # ["id_swissreg:mainContent:id_txf_app_no", ""],                       # Gesuch Nr.
    # ["id_swissreg:mainContent:id_txf_tm_text", marke],
    # ["id_swissreg:mainContent:id_txf_applicant", ""],                    # Inhaber/in
    # ["id_swissreg:mainContent:id_cbxCountry", "_ALL"], # Auswahl Länder _ALL
    # ["id_swissreg:mainContent:id_txf_agent", ""],                         # Vertreter/in
    # ["id_swissreg:mainContent:id_txf_licensee", ""], # Lizenznehmer
    # ["id_swissreg:mainContent:id_txf_nizza_class", ""], # Nizza Klassifikation Nr.
    #      # ["id_swissreg:mainContent:id_txf_appDate", timespan], # Hinterlegungsdatum
    # ["id_swissreg:mainContent:id_txf_appDate",  "%s" % timespan] ,
    # ["id_swissreg:mainContent:id_txf_expiryDate", ""], # Ablauf Schutzfrist
    # Markenart: Individualmarke 1 Kollektivmarke 2 Garantiemarke 3
    # ["id_swissreg:mainContent:id_cbxTMTypeGrp", "_ALL"],  # Markenart
    # ["id_swissreg:mainContent:id_cbxTMForm", "_ALL"],  # Markentyp
    # ["id_swissreg:mainContent:id_cbxTMColorClaim", "_ALL"],  # Farbanspruch
    # ["id_swissreg:mainContent:id_txf_pub_date", ""], # Publikationsdatum

    # info zu Publikationsgrund id_swissreg:mainContent:id_ckbTMPubReason
    # ["id_swissreg:mainContent:id_ckbTMPubReason", "1"], #Neueintragungen
    # ["id_swissreg:mainContent:id_ckbTMPubReason", "2"], #Berichtigungen
    # ["id_swissreg:mainContent:id_ckbTMPubReason", "3"], #Verlängerungen
    # ["id_swissreg:mainContent:id_ckbTMPubReason", "4"], #Löschungen
    # ["id_swissreg:mainContent:id_ckbTMPubReason", "5"], #Inhaberänderungen
    # ["id_swissreg:mainContent:id_ckbTMPubReason", "6"], #Vertreteränderungen
    # ["id_swissreg:mainContent:id_ckbTMPubReason", "7"], #Lizenzänderungen
    # ["id_swissreg:mainContent:id_ckbTMPubReason", "8"], #Weitere Registeränderungen
    # ["id_swissreg:mainContent:id_ckbTMEmptyHits", "0"],  # Leere Trefferliste anzeigen
    # ["id_swissreg:mainContent:id_ckbTMState", "1"], # "Hängige Gesuche 1
    #      # ["id_swissreg:mainContent:id_ckbTMState", "2"], # "Gelöschte Gesuche 2
    # ["id_swissreg:mainContent:id_ckbTMState", "3"], # aktive Marken 3 
    #      # ["id_swissreg:mainContent:id_ckbTMState", "4"], # gelöschte Marken 4

    
    MaxZeilen = 5
    
    attr_accessor :marke
    
    def initialize(timespan)
      @timespan = timespan
      @marke = nil
      @number = nil
      @hitsPerPage = 100
      
      @agent = Mechanize.new { |agent|
        agent.user_agent = 'Mozilla/5.0 (X11; Linux x86_64; rv:16.0) Gecko/20100101 Firefox/16.0'
        agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
        FileUtils.makedirs 'mechanize' if $VERBOSE
        agent.log = Logger.new("mechanize/mechanize.log") if $VERBOSE
      }
      @results = []
      @errors  = Hash.new
      @lastDetail =nil
      @counterDetails = 0
      if false # force some values
        # asp* => 138 records werden geholt
        # a* => Es wurden 25,490 Treffer gefunden. Davon werden 10000 zufällig ausgewählte Schutztitel angezeigt. Bitte schränken Sie Ihre Suche weiter ein.
        #       Ab 501 Treffer wird eine vereinfachte Trefferliste angezeigt.  
        # asp* => 138 records werden geholt

        @marke = 'zzzyyzzzzyzzyz*' # => Fehlermeldung: Es wurden keine Daten gefunden
        @marke = 'aspira' 
        # @number = '500000' # für Weihnachten
        @number = ' 601416' # für aspira
  #      @marke = "*WEIH*"
        @timespan = nil
      end
      @marke = 'asp*'
    end
    
    def writeResponse(filename)
      if defined?(RSpec) or $VERBOSE
        ausgabe = File.open(filename, 'w+')
        ausgabe.puts @agent.page.body
        ausgabe.close
      else
        puts "Skipping writing #{filename}" if $VERBOSE
      end
    end

    def view_state(response)
      if /^1\.8/.match(RUBY_VERSION)
        match = /javax.faces.ViewState.*?value="([^"]+)"/u.match(response)
      else
        match = /javax.faces.ViewState.*?value="([^"]+)"/u.match(response.force_encoding('utf-8'))
      end
      match ? match[1] : ""
    end

    def checkErrors(body)
      BekannteFehler.each {
      |errMsg|
        if body.to_s.index(errMsg)
          puts "Tut mir leid. Suche wurde mit Fehlermeldung <#{errMsg}> abgebrochen."
          exit 2
        end
      }
    end
    
    def parse_swissreg(timespan = @timespan,  # sollte 377 Treffer ergeben, für 01.06.2007-10.06.2007, 559271 wurde in diesem Zeitraum registriert
                      marke = @marke,    
                      nummer =@number) #  nummer = "559271" ergibt genau einen treffer

      # discard this first response
      # swissreg.ch could not handle cookie by redirect.
      # HTTP status code is also strange at redirection.
      @agent.get Start_uri  # get a cookie for the session
      content = @agent.get_file Start_uri
      writeResponse('mechanize/start.jsp')
      # get only view state
      @state = view_state(content)
      data = [
        ["autoScroll", "0,0"],
        ["id_swissreg:_link_hidden_", ""],
        ["id_swissreg_SUBMIT", "1"],
        ["id_swissreg:_idcl", "id_swissreg_sub_nav_ipiNavigation_item0"],
        ["javax.faces.ViewState", @state],
      ]
      
      content = @agent.post(Start_uri, data)  
      writeResponse('mechanize/start2.jsp')
      # Navigation with mechanize like this fails and returns to the home page
      # @agent.page.link_with(:id => "id_swissreg_sub_nav_ipiNavigation_item0").click
      
      data = [
        ["autoScroll", "0,0"],
        ["id_swissreg:_link_hidden_", ""],
        ["id_swissreg_SUBMIT", "1"],
        ["id_swissreg:_idcl", "id_swissreg_sub_nav_ipiNavigation_item0_item3"],
        ["javax.faces.ViewState", @state],
      ]
      # sr1 ist die einfache suche, sr3 die erweiterte Suche
      @path = "/srclient/faces/jsp/trademark/sr3.jsp"
      response = @agent.post(Base_uri + @path, data)
      writeResponse('mechanize/sr3.jsp')
      
      # Fill out form values
      @agent.page.form('id_swissreg').checkboxes.each{ |box| 
                                  TMChoiceFields.index(box.value) ? box.check : box.uncheck 
                                  box.check if $VERBOSE
                                  # select all publication reasons
                                  box.check if /id_ckbTMPubReason/.match(box.name)
                                  # select all publication states
                                  box.check if /id_ckbTMState/.match(box.name)
                                }
      if $VERBOSE # and false # fill all details for marke  567120        
        # Felder, welche nie bei der Antwort auftauchen
        @agent.page.form('id_swissreg').field(:name => 'id_swissreg:mainContent:id_txf_licensee') { |x| x.value = 'BBB Inc*' }
        @agent.page.form('id_swissreg').field(:name => 'id_swissreg:mainContent:id_txf_expiryDate') { |x| x.value = timespan }
        @agent.page.form('id_swissreg').field(:name => 'id_swissreg:mainContent:id_txf_pub_date') { |x| x.value = timespan }
        @agent.page.form('id_swissreg').field(:name => 'id_swissreg:mainContent:id_txf_nizza_class') { |x| x.value = '9' }      
        @agent.page.form('id_swissreg').field(:name => 'id_swissreg:mainContent:id_txf_agent') { |x| x.value = 'Marc Stucki*' }
        @agent.page.form('id_swissreg').field(:name => 'id_swissreg:mainContent:id_cbxCountry') { |x| x.value = 'CH' }  # 'CH' or '_ALL'

        # Felder, welche im Resultat angezeigt werden
        @agent.page.form('id_swissreg').field(:name => 'id_swissreg:mainContent:id_txf_applicant') { |x| x.value = 'ASP ATON*' } #inhaber
        @agent.page.form('id_swissreg').field(:name => 'id_swissreg:mainContent:id_txf_tm_no') { |x| x.value = "567120" }
        @agent.page.form('id_swissreg').field(:name => 'id_swissreg:mainContent:id_txf_app_no') { |x| x.value = '50329/2008' }
      end
      
      # Feld, welches im Resultat angezeigt wird
      @agent.page.form('id_swissreg').field(:name => 'id_swissreg:mainContent:id_txf_tm_text') { |x| x.value = "asp*" }
      
      # Felder, welches nie bei der Antwort auftaucht. Ein Versuch .gsub('.', '%2E') schlug ebenfalls fehl!
      @agent.page.form('id_swissreg').field(:name => 'id_swissreg:mainContent:id_txf_appDate') { |x| x.value = timespan}
      
      # Feld, welches ebenfalls berücksichtigt wird
      @agent.page.form('id_swissreg').field(:name => 'id_swissreg:mainContent:id_cbxHitsPerPage') { |x| x.value = @hitsPerPage }
      @agent.page.form('id_swissreg').field(:name => 'autoScroll') { |x| x.value = '0,0' }
      
      if $VERBOSE
        puts "State of searchForm is:"
        @agent.page.form('id_swissreg').fields.each{ |f| puts "field: #{f.name}: #{f.value}"}  
        @agent.page.form('id_swissreg').checkboxes.each{ |box| puts "#{box.name} checked? #{box.checked}"} 
      end
      
      @agent.page.form('id_swissreg').click_button(@agent.page.form('id_swissreg').button_with(:value => "suchen"))
      # Hier sollten eigentlich alle Felder auftauchen, wie
      # Marke=asp*; Land (Inhaber/in)=Schweiz; Markenart=Alle; Markentyp=Alle; Farbanspruch=Alle; Publikationsgrund= Neueintragungen, Berichtigungen, Verlängerungen, Löschungen, Inhaberänderungen, Vertreteränderungen, Lizenzänderungen, Weitere Registeränderungen; Status= hängige Gesuche, aktive Marken
      writeResponse('mechanize/result.jsp')
    end

    def parseAddress(nummer, zeilen)
      ort = nil
      plz = nil
      
      # Search for plz/address
      1.upto(zeilen.length-1).each  {
        |cnt|
          if    m = AddressRegexp.match(zeilen[cnt])
            zeilen[cnt+1] = nil
            plz = m[1]; ort = m[2]
            cnt.upto(MaxZeilen-1).each{ |cnt2| zeilen[cnt2] = nil }
            break
          end
      }
      unless plz
        puts "Achtung! Konnte Marke #{nummer} mit Inhaber #{zeilen.inspect} nicht parsen" if $VERBOSE
        return nil,   nil,     nil,     nil,     nil,     nil,     nil, nil
      end
      # search for lines with only digits
      found = false
      1.upto(zeilen.length-1).each  {
        |cnt|
          break if zeilen[cnt] == nil
          if /^\d*$/.match(zeilen[cnt])
            found = true
            if zeilen[cnt+1] == nil
              found = 'before'
              zeilen[cnt-1] += LineSplit + zeilen[cnt]
              zeilen.delete_at(cnt)
            else
              found = 'after'
              zeilen[cnt] += LineSplit + zeilen[cnt+1]
              zeilen.delete_at(cnt+1)
            end
          end        
      }
      puts "found #{found}: #{zeilen.inspect}" if found and $VERBOSE
      return zeilen[0], zeilen[1], zeilen[2], zeilen[3], zeilen[4], plz, ort
    end

    def fetchDetails(nummer) # takes a long time!
      @counterDetails += 1
      filename = "mechanize/detail_#{nummer}.html"
      if File.exists?(filename)
        doc = Nokogiri::Slop(File.open(filename))
      else
        url = "https://www.swissreg.ch/srclient/faces/jsp/trademark/sr300.jsp?language=de&section=tm&id=#{nummer}"
        pp "Opening #{url}" if $VERBOSE
        content = @agent.get_file url
        writeResponse("mechanize/detail_#{nummer}.html")
        doc = Nokogiri::Slop(content)
      end
      puts "Bitte um Geduld. Holte Adressdetails für Marke #{nummer}. (#{@counterDetails} von #{@errors.size})"
      path_name = "//html/body/form/div/div/fieldset/div/table/tbody/tr/td"
      counter = 0
      doc.xpath(path_name).each{ 
        |td|
          pp "#{counter}: #{td.text}" if $VERBOSE
          counter += 1
          next unless /^inhaber/i.match(td.text)
          zeilen = []
          doc.xpath(path_name)[counter].children.each{ |child| zeilen << child.text unless child.text.length == 0 } # avoid adding <br>
          if info = @errors[nummer]
            info.inhaber = zeilen.join(" ")
            info.zeile_1, info.zeile_2, info.zeile_3, info.zeile_4, zeile_5, info.plz, info.ort = parseAddress(nummer, zeilen)
            @results << info
          else
            bezeichnung =  doc.xpath(path_name)[15]
            inhaber = zeilen.join(" ")
            zeile_1, zeile_2, zeile_3, zeile_4, zeile_5, plz, ort = parseAddress(nummer, zeilen)
            hinterlegungsdatum = doc.xpath(path_name)[7]
            marke = Marke.new(bezeichnung, nummer,  inhaber,  DefaultCountry,  hinterlegungsdatum, zeile_1, zeile_2, zeile_3, zeile_4, zeile_5, plz, ort )
            @results << marke
          end
      }
    end

    def fetchresult(filename = nil, counter = 1)
      if filename
        doc = Nokogiri::Slop(File.open(filename))        
      else
        body = @agent.page.body
        body.force_encoding('utf-8')
        doc = Nokogiri::Slop(body)
      end
      nrFailures = 0
      counter += 1
      puts "fetchresult. Counter #{counter} already #{@results.size} Datensätze für die Zeitspanne '#{@timespan}'" if $VERBOSE
      path_name = "//html/body/form/div/div/fieldset/table/tbody/tr/td/table/tr/td"
      hasNext = false
      doc.xpath(path_name).each{ 
        |elem|
        if /scroll_1idx#{counter}/.match(elem.to_s)
          hasNext = true
          break
        end
      }
      path_name = "//html/body/form/div/div/fieldset/table/tbody/tr/td/table/tbody/tr"
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
        zeile_1, zeile_2, zeile_3, zeile_4, zeile_5, plz, ort = parseAddress(nummer, inhaber.split(LineSplit))
        if zeile_1
          @results << Marke.new(bezeichnung, elem.elements[2].text,  elem.elements[3].text,  land,  elem.elements[5].text,
                                zeile_1, zeile_2, zeile_3, zeile_4, zeile_5, plz, ort )
        else
          nrFailures += 1
          @errors[nummer] = Marke.new(bezeichnung, elem.elements[2].text,  elem.elements[3].text,  land,  elem.elements[5].text,
                                zeile_1, zeile_2, zeile_3, zeile_4, zeile_5, plz, ort )
        end
      } if doc.xpath(path_name)
      if hasNext
        @path = "/srclient/faces/jsp/trademark/sr30.jsp"
        puts "Calling sub #{counter} with #{@path}" if $VERBOSE
        data = [
          ["autoScroll", "0,0"],
          ["id_swissreg:mainContent:id_sub_options_result:sub_fieldset:id_cbxHitsPerPage", @hitsPerPage],
#          ["id_swissreg:mainContent:vivian", "TRADEMARK REGISTER SEARCH TIMES: QUERY=[20] SELECT=[823] SERVER=[846] DELEGATE=[861] (HITS=[96])"],
          ["id_swissreg_SUBMIT", "1"],
          ["id_swissreg:_idcl",   "id_swissreg:mainContent:scroll_1idx#{counter}"],
          ["id_swissreg:mainContent:scroll_1", "idx#{counter}"],
          ["tmMainId", ""],
          ["id_swissreg:_link_hidden_ "],
          ["javax.faces.ViewState", @state],
        ]
        TMChoiceFields.each{ | field2display| data << ["id_swissreg:mainContent:id_sub_options_result:id_ckbTMChoice", field2display] }
        response = @agent.post(Base_uri + @path, data)
        writeResponse("mechanize/resultate_#{counter}.html")
        checkErrors(response.body)
        fetchresult(nil, counter)
      else
        puts "Es gab #{nrFailures} Fehler beim Lesen von #{filename}"  if $VERBOSE
        puts "Fand #{@results.size} Datensätze für die Zeitspanne '#{@timespan}'. Von #{@errors.size} muss die Adresse noch geholt werden."
      end
    end

    def emitCsv(filename='ausgabe.csv')
      return if @results.size == 0
      if /^1\.8/.match(RUBY_VERSION)
        ausgabe = File.open(filename, 'w+')
        # Write header
        s=''
        @results[0].members.each { |member| s += member + ';' }
        ausgabe.puts s.chop
        # write all line
        @results.each{ 
          |result| 
            s = ''
            result.members.each{ |member| 
                                  unless eval("result.#{member}") 
                                    s += ';'
                                  else
                                    value = eval("result.#{member.to_s}")
                                    value = "\"#{value}\"" if value.index(';')
                                    s += value + ';' 
                                  end
                               }
            ausgabe.puts s.chop
        }        
      else
        CSV.open(filename,  'w', :headers=>@results[0].members,
                                  :write_headers => true,
                                  :col_sep => ';'
                                ) do |csv| @results.each{ |x| csv << x }
        end
      end
    end
      
    def fetchMissingDetails
      @errors.each{ 
        |markennummer, info|
          fetchDetails(markennummer) 
      }
    end
  end # class Swissreg

  def Brand2csv::run(timespan)
    session = Swissreg.new(timespan)
    session.parse_swissreg
    session.fetchresult
    session.fetchMissingDetails
    session.emitCsv("#{timespan}.csv")
  end
  
end # module Brand2csv
