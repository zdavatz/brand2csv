#!/usr/bin/env ruby
#encoding: utf-8

require 'prettyprint'
require 'net/http'
require 'cgi'

# from oddb.org/src/util/http.rb
require 'delegate'
module ODDB
  module HttpFile
    def http_file(server, source, target, session=nil, hdrs = nil)
      if(body = http_body(server, source, session, hdrs))
        dir = File.dirname(target)
        FileUtils.mkdir_p(dir)
        File.open(target, 'w') { |file|
          file << body
        }
        true
      end
    end
    def http_body(server, source, session=nil, hdrs=nil)
      session ||= HttpSession.new server
      hdrs ||= {}
      resp = session.get(source, hdrs)
      if resp.is_a? Net::HTTPOK
        resp.body
      end
    end
  end
  class HttpSession < SimpleDelegator
    class ResponseWrapper < SimpleDelegator
      def initialize(resp)
        @response = resp
        super
      end
      def body
        body = @response.body
        charset = self.charset
        unless(charset.nil? || charset.downcase == 'utf-8')
          cd = Iconv.new("UTF-8//IGNORE", charset)
          begin
            cd.iconv body
          rescue
            body
          end
        else
          body
        end
      end
      def charset
        if((ct = @response['Content-Type']) \
          && (match = /charset=([^;])+/u.match(ct)))
          arr = match[0].split("=")
          arr[1].strip.downcase
        end
      end
    end
    HTTP_CLASS = Net::HTTP
    RETRIES = 3
    RETRY_WAIT = 10
    def initialize(http_server, port=80)
      @http_server = http_server
      @http = self.class::HTTP_CLASS.new(@http_server, port)
      @output = ''
      super(@http)
    end
    def post(path, hash)
      retries = RETRIES
      headers = post_headers
      begin
        #@http.set_debug_output($stderr)
        resp = @http.post(path, post_body(hash), headers)
        case resp
        when Net::HTTPOK
          ResponseWrapper.new(resp)
        when Net::HTTPFound
          uri = URI.parse(resp['location'])
          path = (uri.respond_to?(:request_uri)) ? uri.request_uri : uri.to_s
          warn(sprintf("redirecting to: %s", path))
          get(path)
        else
          raise("could not connect to #{@http_server}: #{resp}")
        end
      rescue Errno::ECONNRESET, EOFError
        if(retries > 0)
          retries -= 1
          sleep RETRIES - retries
          retry
        else
          raise
        end
      end
    end
    def post_headers
      headers = get_headers
      headers.push(['Content-Type', 'application/x-www-form-urlencoded'])
      headers.push(['Referer', @referer.to_s])
    end
    def get(*args)
      retries = RETRIES
      begin
        @http.get(*args)
      rescue Errno::ECONNRESET, Errno::ECONNREFUSED, EOFError
        if(retries > 0)
          retries -= 1
          sleep RETRIES - retries
          retry
        else
          raise
        end
      end
    end
    def get_headers
      [
        ['Host', @http_server],
        ['User-Agent', 'Mozilla/5.0 (X11; Linux x86_64; rv:16.0) Gecko/20100101 Firefox/16.0'],
        ['Accept', 'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,video/x-mng,image/png,image/jpeg,image/gif;q=0.2,*/*;q=0.1'],
        ['Accept-Encoding', 'gzip, deflate'],
        ['Accept-Language', 'de-ch,en-us;q=0.7,en;q=0.3'],
        ['Accept-Charset', 'UTF-8'],
        ['Keep-Alive', '300'],
        ['Connection', 'keep-alive'],
      ]
    end
    def post_body(data)
      sorted = data.collect { |pair| 
        pair.collect { |item| CGI.escape(item) }.join('=') 
      }
      sorted.join("&")
    end
  end
end
# from ddob.org/src/util/session.rb
module ODDB
  module Swissreg
class Session < HttpSession
  def initialize
    host = 'www.swissreg.ch'
    super(host)
    @base_uri = "https://#{host}"
    @http.read_timeout = 120
    @http.use_ssl = true
    @http.instance_variable_set("@port", '443')
    # swissreg does not have sslv3 cert
    #@http.ssl_version = 'SSLv3'
    @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
  def get(url, *args) # this method can not handle redirect
    res = super
    @referer = url
    res
  end
  def fetch(uri, limit = 5)
    raise ArgumentError, 'HTTP redirect too deep' if limit == 0
    url = URI.parse(URI.encode(uri.strip))
    option = {
      :use_ssl     => true,
      # ignore swissreg.ch cert
      :verify_mode => OpenSSL::SSL::VERIFY_NONE
    }
    response = Net::HTTP.start(url.host, option) do |http|
      http.get url.request_uri
    end
    @referer = uri
    case response
    when Net::HTTPSuccess
      response
    when Net::HTTPRedirection
      fetch(response['location'], limit - 1)
    else
      response.value
    end
  end
  
  def detail(url, id, state, param)
    criteria = [
      ["autoScroll", "0,0"],
      ["id_swissreg:_idcl", "id_swissreg:mainContent:data:0:id_detail"],
      ["id_swissreg:_link_hidden_", ""],
      ["id_swissreg:mainContent:id_sub_options_result:id_ckbSpcChoice", "spc_lbl_title"],
      ["id_swissreg:mainContent:id_sub_options_result:id_ckbSpcChoice", "spc_lbl_pat_type"],
      ["id_swissreg:mainContent:id_sub_options_result:id_ckbSpcChoice", "spc_lbl_basic_pat_no"],
      ["id_swissreg:mainContent:id_sub_options_result:sub_fieldset:id_cbxHitsPerPage", "25"],
      ["id_swissreg:mainContent:scroll_1", ""],
      ["id_swissreg:mainContent:vivian", param],
      ["id_swissreg_SUBMIT", "1"],
      ["javax.faces.ViewState", state],
      ["spcMainId", id]
    ]
    response = post(url, criteria)
    update_cookie(response)
    writer = DetailWriter.new
    formatter = ODDB::HtmlFormatter.new(writer)
    parser = ODDB::HtmlParser.new(formatter)
    parser.feed(response.body)
    writer.extract_data
  rescue Timeout::Error
    {}
  end
  def get_headers
    hdrs = super
    if(@cookie_id)
      hdrs.push(['Cookie', @cookie_id])
    end
    hdrs
  end
  def get_result_list(iksnr)
    path = '/srclient/'
    # discard this first response
    # swissreg.ch could not handle cookie by redirect.
    # HTTP status code is also strange at redirection.
    response = fetch(@base_uri + path)
    # get only view state
    state = view_state(response)
    # get cookie
    path = "/srclient/faces/jsp/start.jsp"
    response = fetch(@base_uri + path)
    update_cookie(response)
    data = [
      ["autoScroll", "0,0"],
      ["id_swissreg:_link_hidden_", ""],
      ["id_swissreg_SUBMIT", "1"],
      ["id_swissreg:_idcl", "id_swissreg_sub_nav_ipiNavigation_item10"],
      ["javax.faces.ViewState", state],
    ]
    response = post(@base_uri + path, data)
    # swissreg.ch does not recognize request.
    # we must send same request again :(
    sleep(1)
    response = post(@base_uri + path, data)
    update_cookie(response)
    state = view_state(response)
    data = [
      ["autoScroll", "0,0"],
      ["id_swissreg:_link_hidden_", ""],
      ["id_swissreg:mainContent:id_txf_basic_pat_no",""],
      ["id_swissreg:mainContent:id_txf_spc_no",""],
      ["id_swissreg:mainContent:id_txf_title",""],
      ["id_swissreg_SUBMIT", "1"],
      ["id_swissreg:_idcl", "id_swissreg_sub_nav_ipiNavigation_item10_item13"],
      ["javax.faces.ViewState", state],
    ]
    path = "/srclient/faces/jsp/spc/sr1.jsp"
    response = post(@base_uri + path, data)
    update_cookie(response)
    criteria = [
      ["autoScroll", "0,0"],
      ["id_swissreg:_idcl", ""],
      ["id_swissreg:_link_hidden_", ""],
      ["id_swissreg:mainContent:id_cbxHitsPerPage", "25"],
      ["id_swissreg:mainContent:id_cbxSpcAppCountry", "_ALL"],
      ["id_swissreg:mainContent:id_cbxSpcAppSearchMode", "_ALL"],
      ["id_swissreg:mainContent:id_cbxSpcAuthority", "_ALL"],
      ["id_swissreg:mainContent:id_cbxSpcFormatChoice", "1"],
      ["id_swissreg:mainContent:id_cbxSpcLanguage", "_ALL"],
      ["id_swissreg:mainContent:id_ckbSpcChoice", "spc_lbl_title"],
      ["id_swissreg:mainContent:id_ckbSpcChoice", "spc_lbl_pat_type"],
      ["id_swissreg:mainContent:id_ckbSpcChoice", "spc_lbl_basic_pat_no"],
      ["id_swissreg:mainContent:id_ckbSpcPubReason", "1"],
      ["id_swissreg:mainContent:id_ckbSpcPubReason", "2"],
      ["id_swissreg:mainContent:id_ckbSpcPubReason", "7"],
      ["id_swissreg:mainContent:id_ckbSpcPubReason", "8"],
      ["id_swissreg:mainContent:id_ckbSpcPubReason", "3"],
      ["id_swissreg:mainContent:id_ckbSpcPubReason", "4"],
      ["id_swissreg:mainContent:id_ckbSpcPubReason", "5"],
      ["id_swissreg:mainContent:id_ckbSpcPubReason", "6"],
      ["id_swissreg:mainContent:id_ckbSpcViewState", "act"],
      ["id_swissreg:mainContent:id_ckbSpcViewState", "pen"],
      ["id_swissreg:mainContent:id_ckbSpcViewState", "del"],
      ["id_swissreg:mainContent:id_txf_agent", ""],
      ["id_swissreg:mainContent:id_txf_app_city", ""],
      ["id_swissreg:mainContent:id_txf_app_date", ""],
      ["id_swissreg:mainContent:id_txf_applicant", ""],
      ["id_swissreg:mainContent:id_txf_auth_date", ""],
      ["id_swissreg:mainContent:id_txf_auth_no", iksnr],
      ["id_swissreg:mainContent:id_txf_basic_pat_no", ""],
      ["id_swissreg:mainContent:id_txf_basic_pat_start_date", ""],
      ["id_swissreg:mainContent:id_txf_del_date", ""],
      ["id_swissreg:mainContent:id_txf_expiry_date", ""],
      ["id_swissreg:mainContent:id_txf_grant_date", ""],
      ["id_swissreg:mainContent:id_txf_pub_app_date", ""],
      ["id_swissreg:mainContent:id_txf_pub_date", ""],
      ["id_swissreg:mainContent:id_txf_spc_no", ""],
      ["id_swissreg:mainContent:id_txf_title", ""],
      ["id_swissreg:mainContent:sub_fieldset:id_submit", "suchen"],
      ["id_swissreg_SUBMIT", "1"],
      ["javax.faces.ViewState", view_state(response)]
    ]
    path = "/srclient/faces/jsp/spc/sr3.jsp"
    response = post(@base_uri + path, criteria)
    update_cookie(response)
    extract_result_links(response)
  rescue Timeout::Error
    []
  end
  def post(url, *args)
    res = super
    @referer = url
    res
  end
  def update_cookie(response)
    if(hdr = response['set-cookie'])
      @cookie_id = hdr[/^[^;]+/u]
    end
  end
  def view_state(response)
    if match = /javax.faces.ViewState.*?value="([^"]+)"/u.match(response.body.force_encoding('utf-8'))
      match[1]
    else
      ""
    end
  end

  # Neu von Niklaus
  def writeResponse(filename, body)
    ausgabe = File.open(filename, 'w+')
    ausgabe.puts body
    ausgabe.close
  end
  
  def getSimpleMarkenSuche(timespan = "1.11.2011-5.11.2011", marke = "")
    puts("getSimpleMarkenSuche #{timespan}")
    path = '/srclient/'
    # discard this first response
    # swissreg.ch could not handle cookie by redirect.
    # HTTP status code is also strange at redirection.
    response = fetch(@base_uri + path)
    # get only view state
    state = view_state(response)
    # get cookie
    path = "/srclient/faces/jsp/start.jsp"
    response = fetch(@base_uri + path)
    update_cookie(response)
    data = [
      ["autoScroll", "0,0"],
      ["id_swissreg:_link_hidden_", ""],
      ["id_swissreg_SUBMIT", "1"],
      ["id_swissreg:_idcl", "id_swissreg_sub_nav_ipiNavigation_item0"],
      ["javax.faces.ViewState", state],
    ]
    
    response = post(@base_uri + path, data)
    # swissreg.ch does not recognize request.
    # we must send same request again :(
    sleep(1)
    response = post(@base_uri + path, data)
    writeResponse('einfache_suche.html', response.body)
    update_cookie(response)
    state = view_state(response)
    data = [
      ["autoScroll", "0,0"],
      ["id_swissreg:_link_hidden_", ""],
      ["id_swissreg_SUBMIT", "1"],
      ["id_swissreg:_idcl", "id_swissreg_sub_nav_ipiNavigation_item0_item3"],
      ["javax.faces.ViewState", state],
    ]
        
    # sr1 ist die einfache suche, sr3 die erweiterte Suche
    path = '/srclient/faces/jsp/trademark/sr3.jsp'
    response = post(@base_uri + path, data)
    body = response.body
    writeResponse('erweiterte_suche.html', response.body)
    update_cookie(response)
    state = view_state(response)
    # Grösste angezeigte Anzahl bis jetzt 441
    # Bei grosser Anzahl kommt (ab 981)
    # Gemäss https://www.swissreg.ch/help/de/sr2000.shtm 
    # Bitte beachten Sie, dass insgesamt maximal 500 Treffer angezeigt werden. Sollte Ihre Suche mehr als 500 Treffer ergeben, wird eine vereinfachte Trefferliste angezeigt. Sollte Ihre Suche mehr als 10’000 Treffer ergeben, dann werden willkürlich 10’000 Treffer ausgewählt und angezeigt.

    x = %(
    Es wurden 35,539 Treffer gefunden. Davon werden 10,000 zufällig ausgewählte Schutztitel angezeigt.

Aufgrund der grossen Datenmenge wird Ihnen eine vereinfachte Trefferliste angezeigt. Alternativ können Sie die Suche weiter einschränken damit Ihnen die vollständige Trefferliste zur Verfügung steht.
  # Link nach /srclient/faces/jsp/trademark/show_simple_view.jsp.
)
    # ngng 0 formular">Markenart</td><td class="w300"><select id="id_swissreg:mainContent:id_cbxTMTypeGrp
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
    
    # Somehow the criteria does not get posted correctly
    response =  post(@base_uri + path, criteria)
    update_cookie(response)
    # Hier kommt jedoch die Seite mit Suchkriterien 
    # https://www.swissreg.ch/help/de/trademark/sr3000.shtm#cbxCountry
    body = response.body
    unless body.index('Schutztitel') or  body.index('Suchkriterien')
      hilfeName = 'hilfeseite.html'
      writeResponse(hilfeName, response.body)
      puts "Tut mir leid! and nur die Hilfeseite. Schrieb #{hilfeName}"
      exit
    end

    # Weitere gesehene Fehler
    bekannteFehler = 
        ['Das Datum ist ung', # ültig'
          'Es wurden keine Daten gefunden.',
          'Die Suchkriterien sind teilweise unzul', # ässig',
          'Geben Sie mindestens ein Suchkriterium ein',
          'Die Suche wurde abgebrochen, da die maximale Suchzeit von 60 Sekunden',
        ]
    # » Die Suche wurde abgebrochen, da die maximale Suchzeit von 60 Sekunden überschritten wurde. Bitte formulieren Sie eine präzisere Suche.
    bekannteFehler.each {
      |errMsg|
        if body.to_s.index(errMsg)
          infoName = 'infoseite.html'
          writeResponse(infoName, response.body)
          writeResponse('infoseite.html', response.body)
          puts "Tut mir leid. Fand Fehlermeldung <#{errMsg}<. Erstellte nur eine Infoseite #{infoName}."
          exit 2
        end
      }
   
    name = 'resultat_1.html'
    x = /([\d,]*)\D* Treffer gefunden/.match(body)
    if x 
      puts "Fand #{x[1]} Resultate für #{timespan}  "
    end
    x = /Treffer (\d*)-(\d*) von (\d*)/.match(body)
    if x 
      puts "Fand #{x[0]} für #{timespan} "
    end

    puts "Resultate für  #{timespan}  scheinen gültig zu sein. Schreibe Datei #{name}"
    writeResponse(name, response.body)
  end
  
end
  end
end

mySession = ODDB::Swissreg::Session.new
mySession.getSimpleMarkenSuche( "1.10.2011-5.10.2011", "asp*")

