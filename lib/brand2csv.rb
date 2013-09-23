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


  class Marke < Struct.new(:name, :markennummer, :inhaber, :land, :hatVertreter, :hinterlegungsdatum, :zeile_1, :zeile_2, :zeile_3, :zeile_4, :zeile_5, :plz, :ort)
  end

  class Swissreg
    
      # Weitere gesehene Fehler
    BekannteFehler = 
          ['Das Datum ist ung', # ültig'
           '500 Internal Server Error',
           'Vereinfachte Trefferliste anzeigen',
            'Es wurden keine Daten gefunden.',
            'Die Suchkriterien sind teilweise unzul', # ässig',
            'Geben Sie mindestens ein Suchkriterium ein',
            'Die Suche wurde abgebrochen, da die maximale Suchzeit von 60 Sekunden',
           'Erweiterte Suche',
          ]
    Base_uri = 'https://www.swissreg.ch'
    Start_uri = "#{Base_uri}/srclient/faces/jsp/start.jsp"
    Sr1      = "#{Base_uri}/srclient/faces/jsp/trademark/sr1.jsp"
    Sr2      = "#{Base_uri}/srclient/faces/jsp/trademark/sr2.jsp"
    Sr3      = "#{Base_uri}/srclient/faces/jsp/trademark/sr3.jsp"
    Sr30     = "#{Base_uri}/srclient/faces/jsp/trademark/sr30.jsp"
    Sr300    = "#{Base_uri}/srclient/faces/jsp/trademark/sr300.jsp"
    DetailRegexp  = /d_swissreg:mainContent:data:(\d*):tm_no_detail:id_detail/i
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
            "tm_lbl_agent", # Vertreter/in
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
    HitsPerPage = 250
    LogDir = 'log'
    
    attr_accessor :marke, :results, :timespan
    
    def initialize(timespan, marke = nil, swiss_only=false)
      @timespan = timespan
      @marke = marke
      @swiss_only = swiss_only
      @number = nil
      @results = []
      @all_trademark_numbers = []
      @errors  = Hash.new
      @lastDetail =nil
      @counterDetails = 0
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

    def checkErrors(body, exitIfFailure = true)
      BekannteFehler.each {
      |errMsg|
        if body.to_s.index(errMsg)
          if exitIfFailure
            puts "Tut mir leid. Suche wurde mit Fehlermeldung <#{errMsg}> abgebrochen."
            exit 2
          else
            puts "Info: Suche meldet <#{errMsg}> "
          end
        end
      }
    end
    
    UseClick = false
    
    # Initialize a session with swissreg and save the cookie as @state
    def init_swissreg
      begin
        @agent = Mechanize.new { |agent|
          agent.user_agent = 'Mozilla/5.0 (X11; Linux x86_64; rv:16.0) Gecko/20100101 Firefox/16.0'
          agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
          FileUtils.makedirs(LogDir) if $VERBOSE or defined?(RSpec)
          agent.log = Logger.new("#{LogDir}/mechanize.log") if $VERBOSE
        }
        @agent.get_file  Start_uri # 'https://www.swissreg.ch/srclient/faces/jsp/start.jsp'
        writeResponse("#{LogDir}/session_expired.html")
        checkErrors(@agent.page.body, false)
        @agent.page.links[3].click
        writeResponse("#{LogDir}/homepage.html")
        @state = @agent.page.form["javax.faces.ViewState"]
      rescue Net::HTTPInternalServerError, Mechanize::ResponseCodeError
        puts "Net::HTTPInternalServerError oder Mechanize::ResponseCodeError gesehen.\n   #{Base_uri} hat wahrscheinlich Probleme"
        exit 3
      end
    end
    
    def parse_swissreg(timespan = @timespan,  # sollte 377 Treffer ergeben, für 01.06.2007-10.06.2007, 559271 wurde in diesem Zeitraum registriert
                      marke = @marke,    
                      nummer =@number) #  nummer = "559271" ergibt genau einen treffer

      init_swissreg
      data = [
        ["autoScroll", "0,0"],
        ["id_swissreg:_link_hidden_", ""],
        ["id_swissreg_SUBMIT", "1"],
        ["id_swissreg:_idcl", "id_swissreg_sub_nav_ipiNavigation_item0"],
        ["javax.faces.ViewState", @state],
      ]
      @agent.page.form['id_swissreg:_idcl'] = 'id_swissreg_sub_nav_ipiNavigation_item0'
      @agent.page.forms.first.submit
      writeResponse("#{LogDir}/trademark_simple.html")
      data = [
        ["autoScroll", "0,0"],
        ["id_swissreg:_link_hidden_", ""],
        ["id_swissreg_SUBMIT", "1"],
        ["id_swissreg:_idcl", "id_swissreg_sub_nav_ipiNavigation_item0_item3"],
        ["javax.faces.ViewState", @state],
      ]
      @agent.page.form['id_swissreg:_idcl'] = 'id_swissreg_sub_nav_ipiNavigation_item0_item3'
      @agent.page.forms.first.submit
      writeResponse("#{LogDir}/trademark_extended.html")
      
      data = [
        ["autoScroll", "0,829"],
        ["id_swissreg:_link_hidden_", ""],
        ["id_swissreg:mainContent:id_ckbTMState", "1"], # Hängige Gesuche 1
        ["id_swissreg:mainContent:id_ckbTMState", "3"], # Aktive Marken 3
        ["id_swissreg:mainContent:id_txf_tm_no", ""],# Marken Nr
        ["id_swissreg:mainContent:id_txf_app_no", ""],                       # Gesuch Nr.
        ["id_swissreg:mainContent:id_txf_tm_text", "#{marke}"],
        ["id_swissreg:mainContent:id_txf_applicant", ""],                    # Inhaber/in
        ["id_swissreg:mainContent:id_cbxCountry", @swiss_only ? 'CH' : '_ALL'],
        ["id_swissreg:mainContent:id_txf_agent", ""],                         # Vertreter/in
        ["id_swissreg:mainContent:id_txf_licensee", ""], # Lizenznehmer
        ["id_swissreg:mainContent:id_txf_nizza_class", ""], # Nizza Klassifikation Nr.
        ["id_swissreg:mainContent:id_txf_appDate", "#{timespan}"] ,
        ["id_swissreg:mainContent:id_txf_expiryDate", ""], # Ablauf Schutzfrist
        ["id_swissreg:mainContent:id_cbxTMTypeGrp", "_ALL"],  # Markenart
        ["id_swissreg:mainContent:id_cbxTMForm", "_ALL"],  # Markentyp
        ["id_swissreg:mainContent:id_cbxTMColorClaim", "_ALL"],  # Farbanspruch
        ["id_swissreg:mainContent:id_txf_pub_date", ""], # Publikationsdatum
        ["id_swissreg:mainContent:id_ckbTMPubReason", '1'],
        ["id_swissreg:mainContent:id_ckbTMPubReason", '2'],
        ["id_swissreg:mainContent:id_ckbTMPubReason", '3'],
        ["id_swissreg:mainContent:id_ckbTMPubReason", '4'],
        ["id_swissreg:mainContent:id_ckbTMPubReason", '5'],
        ["id_swissreg:mainContent:id_ckbTMPubReason", '6'],
        ["id_swissreg:mainContent:id_ckbTMPubReason", '7'],
        ["id_swissreg:mainContent:id_ckbTMPubReason", '8'],
        ["id_swissreg:mainContent:id_cbxFormatChoice", "1"],
        ["id_swissreg:mainContent:id_ckbTMChoice", "tm_lbl_tm_text"],
        ["id_swissreg:mainContent:id_ckbTMChoice", "tm_lbl_applicant"],
        ["id_swissreg:mainContent:id_ckbTMChoice", "tm_lbl_country"],
        ["id_swissreg:mainContent:id_ckbTMChoice", "tm_lbl_agent"],
        ["id_swissreg:mainContent:id_ckbTMChoice", "tm_lbl_app_date"],
        ["id_swissreg:mainContent:id_cbxHitsPerPage", HitsPerPage],   # Treffer pro Seite
        ["id_swissreg:mainContent:sub_fieldset:id_submit", "suchen"],
        ["id_swissreg_SUBMIT", "1"],
        ["id_swissreg:_idcl", ""],
        ["id_swissreg:_link_hidden_", ""],
        ["javax.faces.ViewState", @state],
      ]
      begin
        @agent.post(Sr3, data)
      rescue Timeout::Error 
        puts "Timeout!"
        retry
      end
      writeResponse("#{LogDir}/first_results.html")
      checkErrors(@agent.page.body, false)
    end

    # the number is only passed to facilitate debugging
    # lines are the address lines 
    def Swissreg::parseAddress(number, inhaber)
      ort = nil
      plz = nil
      if inhaber
        lines = CGI.unescapeHTML(inhaber).split(LineSplit)
        # Search for plz/address
        1.upto(lines.length-1).each  {
          |cnt|
            if    m = AddressRegexp.match(lines[cnt])
              lines[cnt+1] = nil
              plz = m[1]; ort = m[2]
              cnt.upto(MaxZeilen-1).each{ |cnt2| lines[cnt2] = nil }
              break
            end
        }
      end
      unless plz
        puts "Achtung! Konnte Marke #{number} mit Inhaber #{lines.inspect} nicht parsen" if $VERBOSE
        return nil,   nil,     nil,     nil,     nil,     nil,     nil, nil
      end
      # search for lines with only digits
      found = false
      1.upto(lines.length-1).each  {
        |cnt|
          break if lines[cnt] == nil
          if /^\d*$/.match(lines[cnt])
            found = true
            if lines[cnt+1] == nil
              found = 'before'
              lines[cnt-1] += LineSplit + lines[cnt]
              lines.delete_at(cnt)
            else
              found = 'after'
              lines[cnt] += LineSplit + lines[cnt+1]
              lines.delete_at(cnt+1)
            end
          end        
      }
      puts "found #{found}: #{lines.inspect}" if found and $VERBOSE
      return lines[0], lines[1], lines[2], lines[3], lines[4], plz, ort
    end

    def Swissreg::getInputValuesFromPage(body) # body of HTML page
      contentData = []
      body.search('input').each{ |input| 
                                # puts "name: #{input.attribute('name')} value #{input.attribute('value')}" 
                                contentData << [ input.attribute('name').to_s, input.attribute('value').to_s ]
                                }
      contentData
    end
    
    # return value of an array of POST values
    def Swissreg::inputValue(values, key)
      values.each{ |val| 
                   return val[1] if key.eql?(val[0])
                }
      return nil
    end
    
    # set value for a key of an array of POST values
    def Swissreg::setInputValue(values, key, newValue)
      values.each{ |val| 
                    if key.eql?(val[0])
                      val[1] = newValue
                      return
                    end
                }
      return
    end
    
    def Swissreg::setAllInputValue(form, values)
      values.each{ |newValue|
#                 puts "x: 0 #{ newValue[0].to_s} 1 #{newValue[1].to_s}"
                    form.field(:name => newValue[0].to_s) { |elem| 
                                                            next if elem == nil # puts "Cannot set #{newValue[0].to_s}"
                                                            elem.value = newValue[1].to_s 
                                                          }
                 }
    end

    def Swissreg::getMarkenInfoFromDetail(doc)
      marke = nil
      number = 'invalid'
      bezeichnung = nil
      inhaber = nil
      hinterlegungsdatum = nil
      hatVertreter = false
      doc.xpath("//html/body/form/div/div/fieldset/div/table/tbody/tr").each{ 
        |x|
          if x.children.first.text.eql?('Marke')
            if x.children[1].text.index('Markenabbildung')
              # we must fetch the link to the image
              bezeichnung =  x.children[1].elements.first.attribute('href').text
            else # we got a trademark
              bezeichnung = x.children[1].text 
            end
          end

          if x.children.first.text.eql?('Inhaber/in')
             inhaber = />(.*)<\/td/.match(x.children[1].to_s)[1].gsub('<br>',LineSplit)
          end
          
          if x.children.first.text.eql?('Vertreter/in')
            hatVertreter = true if x.children[1].text.length > 0
          end
          hinterlegungsdatum = x.children[1].text if x.children.first.text.eql?('Hinterlegungsdatum')           
          number = x.children[1].text if x.children.first.text.eql?('Gesuch Nr.')           
      }
      zeile_1, zeile_2, zeile_3, zeile_4, zeile_5, plz, ort = Swissreg::parseAddress(number, inhaber)
      inhaber = inhaber.split(', , ')[0] # Catch cases where Inhaber has several postal addresses
      marke = Marke.new(bezeichnung, number,  inhaber, DefaultCountry, hatVertreter, hinterlegungsdatum, zeile_1, zeile_2, zeile_3, zeile_4, zeile_5, plz, ort )
    end
    
    def fetchDetails(nummer) # takes a long time!
      @counterDetails += 1
      init_swissreg if @counterDetails % 90 == 0 # it seems that swissreg is artificially slowing down serving request after 100 hits
      filename = "#{LogDir}/detail_#{sprintf('%05d', @counterDetails)}_#{nummer.gsub('/','.')}.html"
      if File.exists?(filename)
        doc = Nokogiri::Slop(File.open(filename))
      else
        url = "#{Sr300}?language=de&section=tm&id=#{nummer}"
        pp "#{Time.now.strftime("%H:%M:%S")}: Opening #{filename}" if $VERBOSE
        $stdout.flush
        nrRetries = 0
        begin
          content = @agent.get_file url
          body = @agent.page.body
        rescue 'getaddrinfo: Name or service not known', Exception => e
          nrRetries += 1
          puts e.backtrace
          if nrRetries <= 3
            puts "get_file did not work reinit session and retry for #{nr}. nrRetries #{nrRetries}/3. e #{e}"
            sleep 60  # Sleep a minute to let network recover
            init_swissreg
            retry
          else
            puts "get_file did not work reinit session raise Interrupt"
            raise Interrupt
          end
        end
        body.force_encoding('utf-8') unless /^1\.8/.match(RUBY_VERSION)
        doc = Nokogiri::Slop(body)
        writeResponse(filename)
      end
      marke =  Swissreg::getMarkenInfoFromDetail(doc)
      @results << marke
    end

    def Swissreg::emitCsv(results, filename='ausgabe.csv')
      return if results == nil or results.size == 0
      if /^1\.8/.match(RUBY_VERSION)
        ausgabe = File.open(filename, 'w+')
        # Write header
        s=''
        results[0].members.each { |member| s += member + ';' }
        ausgabe.puts s.chop
        # write all line
        results.each{ 
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
        ausgabe.close
      else
        
        CSV.open(filename,  'w', :headers=>results[0].members,
                                  :write_headers => true,
                                  :col_sep => ';'
                                ) do |csv| results.each{ |x| csv << x }
        end
      end
    end
    
    def Swissreg::getTrademarkNumbers(doc)
      trademark_numbers = []
      doc.search('a').each{ 
        |link| 
          if DetailRegexp.match(link.attribute('id'))
            trademark_numbers << link.children.first.children.first.content
          end
      }
      trademark_numbers
    end
    
    class Swissreg::Vereinfachte
      attr_reader :links2details, :trademark_search_id, :inputData, :firstHit, :nrHits, :nrSubPages, :pageNr
      HitRegexpDE = /Seite (\d*) von ([\d']*) - Treffer ([\d']*)-([\d']*) von ([\d']*)/
      Vivian      = 'id_swissreg:mainContent:vivian'
      
      # Parse a HTML page from swissreg sr3.jsp
      # There we find info like "Seite 1 von 26 - Treffer 1-250 von 6'349" and upto 250 links to details
      def initialize(doc)
        @inputData = []
        @pageNr = @nrSubPages = @firstHit = @nrHits = 0
        m = HitRegexpDE.match(doc.text)
        if m
          begin
            c = m.to_a.map{|n| n.gsub(/'/, "").to_i }
            @pageNr     = c[1]
            @nrSubPages = c[2]
            @firstHit   = c[3]
            @nrHits     = c[5]
          rescue NoMethodError
          end
        end
        @trademark_search_id = Swissreg::inputValue(Swissreg::getInputValuesFromPage(doc), Vivian)
        @links2details = []
        doc.search('input').each{ |input| 
                                # puts "name: #{input.attribute('name')} value #{input.attribute('value')}" if $VERBOSE
                                @inputData << [ input.attribute('name').to_s, input.attribute('value').to_s ]
                                }
        
        @state = Swissreg::inputValue(Swissreg::getInputValuesFromPage(doc),  'javax.faces.ViewState')
        doc.search('a').each{ 
          |link| 
            if m = DetailRegexp.match(link.attribute('id'))
              # puts "XXX #{link.attribute('onclick').to_s} href: #{link.attribute('href').to_s} value #{link.attribute('value').to_s}" if $VERBOSE
              m  = /'tmMainId','(\d*)'/.match(link.attribute('onclick').to_s)
              tmMainId = m[1].to_i
              @links2details << tmMainId
            end      
        }      
      end
      
      def getPostDataForDetail(position, id)
        [
          [ "autoScroll", "0,0"],
          [ "id_swissreg:mainContent:sub_options_result:sub_fieldset:cbxHitsPerPage", "#{HitsPerPage}"],
          [ "id_swissreg:mainContent:vivian", @trademark_search_id],
          [ "id_swissreg_SUBMIT", "1"],
          [ "id_swissreg:_idcl", "id_swissreg:mainContent:data:#{position}:tm_no_detail:id_detail", ""],
          [ "id_swissreg:mainContent:scroll_1", ""],
          [ "tmMainId", "#{id}"],
          [ "id_swissreg:_link_hidden_ "],
          [ "javax.faces.ViewState", @state]
        ]
      end

      def getPostDataForSubpage(pageNr)
        [
          [ "autoScroll", "0,0"],
          [ "id_swissreg:mainContent:sub_options_result:sub_fieldset:cbxHitsPerPage", "#{HitsPerPage}"],
          [ "id_swissreg:mainContent:vivian", @trademark_search_id],
          [ "id_swissreg_SUBMIT", "1"],
          [ "id_swissreg:_idcl", "id_swissreg:mainContent:scroll_1idx#{pageNr}"],
          [ "id_swissreg:mainContent:scroll_1", "idx#{pageNr}"],
          [ "tmMainId", ""],
          [ "id_swissreg:_link_hidden_ "],
          [ "javax.faces.ViewState", @state]
        ]
      end
      
    end
      
    def getAllHits(filename = nil, pageNr = 1)
      if filename && File.exists?(filename)
        doc = Nokogiri::Slop(File.open(filename))        
      else
        form = @agent.page.form
        btn  = form.buttons.last
        if btn && btn.name == "id_swissreg:mainContent:id_show_simple_view_hitlist"
          res = @agent.submit(form, btn)
          body = res.body
        else
         body = @agent.page.body
        end
        body.force_encoding('utf-8') unless /^1\.8/.match(RUBY_VERSION)
        doc = Nokogiri::Slop(body)
        filename = "#{LogDir}/vereinfachte_#{pageNr}.html"
        writeResponse(filename)
      end
      einfach = Swissreg::Vereinfachte.new(doc)
      puts "#{Time.now.strftime("%H:%M:%S")} status: getAllHits for #{pageNr} of #{einfach.nrSubPages} pages"  if $VERBOSE
      subPage2Fetch = pageNr + 1
      data2 = einfach.getPostDataForSubpage(subPage2Fetch).clone
      if (HitsPerPage < einfach.nrHits - einfach.firstHit)
        itemsToFetch = HitsPerPage
      else
        itemsToFetch = einfach.nrHits - einfach.firstHit
      end
      @all_trademark_numbers += Swissreg::getTrademarkNumbers(doc)

      filename = "#{LogDir}/vereinfachte_#{pageNr}_back.html"
      writeResponse(filename)
      if pageNr < (einfach.nrSubPages)
        Swissreg::setAllInputValue(@agent.page.forms.first, data2)
        @agent.page.forms.first.submit
        getAllHits(nil, subPage2Fetch)
      end      
      @all_trademark_numbers
    end

    def fetchresult(filename =  "#{LogDir}/fetch_1.html", counter = 1)
      if filename && File.exists?(filename)
        doc = Nokogiri::Slop(File.open(filename))        
      else
        body = @agent.page.body
        body.force_encoding('utf-8') unless /^1\.8/.match(RUBY_VERSION)
        doc = Nokogiri::Slop(body)
        writeResponse(filename)
      end
      
      if /Vereinfachte Trefferliste anzeigen/i.match(doc.text)
        form = @agent.page.forms.first
        button = form.button_with(:value => /Vereinfachte/i)
        # submit the form using that button
        @agent.submit(form, button)
        filename =  "#{LogDir}/vereinfacht.html"
        writeResponse(filename)
      end
      getAllHits(doc, counter)
      puts"getAllHits: returned #{@all_trademark_numbers ? @all_trademark_numbers.size : 0} hits "
      if @all_trademark_numbers
        @all_trademark_numbers.each{ 
          |nr|
            nrRetries = 0
            begin
              fetchDetails(nr)
            rescue SocketError, Exception => e
              nrRetries += 1
              puts e.backtrace
              if nrRetries <= 3
                puts "fetchDetails did not work reinit session and retry for #{nr}. nrRetries #{nrRetries}/3. e #{e}"
                sleep 60  # Sleep a minute to let network recover
                init_swissreg
                retry
              else
                puts "fetchDetails did not work reinit session raise Interrupt"
                raise Interrupt
              end
            end
        
        }
      else
        puts "Could not find any trademarks in #{filename}"
      end
    end
  end # class Swissreg
  
  def Brand2csv::run(timespan, marke = 'a*', swiss_only = false)
    session = Swissreg.new(timespan, marke, swiss_only)
    begin
      session.parse_swissreg
      session.fetchresult
    rescue Interrupt, Net::HTTP::Persistent::Error
      puts "Unterbrochen. Vesuche #{session.results.size} Resultate zu speichern"
    end
    Swissreg::emitCsv(session.results, "#{timespan}.csv")
    session.results
  end
  
end # module Brand2csv
