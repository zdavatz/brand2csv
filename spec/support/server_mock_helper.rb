#!/usr/bin/env ruby
# encoding: utf-8

module ServerMockHelper
  
  def setup_swissreg_ch_server(trademark, timespan, result_folder, trademark_ids)
    # main
    stub_response = File.read(File.expand_path("../../data/main.html", __FILE__))
    stub_request(:get, "https://www.swissreg.ch/srclient/faces/jsp/start.jsp").
      with(
        :headers => {
          "Accept" => "*/*",
          "Host"   => "www.swissreg.ch",
        }).
      to_return(
        :status  => 200,
        :headers => {"Content-Type" => 'text/html; charset=utf-8'},
        :body    => stub_response)
    # erweiterte
    stub_response = File.read(File.expand_path("../../data/erweiterte_suche.html", __FILE__))
    stub_request(:post,  "https://www.swissreg.ch/srclient/faces/jsp/start.jsp").
      with(
        :headers => {
          "Accept" => "*/*",
          "Host"   => "www.swissreg.ch",
        },
        :body => {
          "autoScroll"                => "",
          "id_swissreg:_idcl"         => "id_swissreg_sub_nav_ipiNavigation_item0",
          "id_swissreg:_link_hidden_" => "",
          "id_swissreg_SUBMIT"        => "1",
          "javax.faces.ViewState"     =>"rO0ABXVyABNbTGphdmEubGFuZy5PYmplY3Q7kM5YnxBzKWwCAAB4cAAAAAN0AAExcHQADi9qc3Avc3RhcnQuanNw"
        }).
      to_return(
        :status  => 200,
        :headers => {"Content-Type" => 'text/html; charset=utf-8'},
        :body    => stub_response)
    # result page 1
    stub_response = File.read(File.expand_path("../../data/#{result_folder}/first_results.html", __FILE__))
    stub_request(:post,  "https://www.swissreg.ch/srclient/faces/jsp/trademark/sr3.jsp").
      with(
        :headers => {
          "Accept" => "*/*",
          "Host"   => "www.swissreg.ch",
        },
        :body => {
          "autoScroll"                                     => "0,829",
          "id_swissreg:_idcl"                              => "",
          "id_swissreg:_link_hidden_"                      => "",
          "id_swissreg:mainContent:id_cbxCountry"          => "_ALL",
          "id_swissreg:mainContent:id_cbxFormatChoice"     => "1",
          "id_swissreg:mainContent:id_cbxHitsPerPage"      => "250",
          "id_swissreg:mainContent:id_cbxTMColorClaim"     => "_ALL",
          "id_swissreg:mainContent:id_cbxTMForm"           => "_ALL",
          "id_swissreg:mainContent:id_cbxTMTypeGrp"        => "_ALL",
          "id_swissreg:mainContent:id_ckbTMChoice"         => "tm_lbl_app_date",
          "id_swissreg:mainContent:id_ckbTMPubReason"      => "8",
          "id_swissreg:mainContent:id_ckbTMState"          => "3",
          "id_swissreg:mainContent:id_txf_agent"           => "",
          "id_swissreg:mainContent:id_txf_appDate"         => "#{timespan}",
          "id_swissreg:mainContent:id_txf_app_no"          => "",
          "id_swissreg:mainContent:id_txf_applicant"       => "",
          "id_swissreg:mainContent:id_txf_expiryDate"      => "",
          "id_swissreg:mainContent:id_txf_licensee"        => "",
          "id_swissreg:mainContent:id_txf_nizza_class"     => "",
          "id_swissreg:mainContent:id_txf_pub_date"        => "",
          "id_swissreg:mainContent:id_txf_tm_no"           => "",
          "id_swissreg:mainContent:id_txf_tm_text"         => "#{trademark}",
          "id_swissreg:mainContent:sub_fieldset:id_submit" => "suchen",
          "id_swissreg_SUBMIT"                             => "1",
          "javax.faces.ViewState"                          => "rO0ABXVyABNbTGphdmEubGFuZy5PYmplY3Q7kM5YnxBzKWwCAAB4cAAAAAN0AAExcHQADi9qc3Avc3RhcnQuanNw"
        }).
      to_return(
        :status  => 200,
        :headers => {"Content-Type" => 'text/html; charset=utf-8'},
        :body    => stub_response)
    # result page 2
    stub_response = File.read(File.expand_path("../../data/#{result_folder}/first_results.html", __FILE__))
    stub_request(:post,  "https://www.swissreg.ch/srclient/faces/jsp/trademark/sr3.jsp").
      with(
        :headers => {
          "Accept" => "*/*",
          "Host"   => "www.swissreg.ch",
        },
        :body => {
          "autoScroll"                                 => "",
          "id_swissreg:_idcl"                          => "id_swissreg_sub_nav_ipiNavigation_item0_item3",
          "id_swissreg:_link_hidden_"                  => "",
          "id_swissreg:mainContent:id_cbxCountry"      => "_ALL",
          "id_swissreg:mainContent:id_cbxFormatChoice" => "1",
          "id_swissreg:mainContent:id_cbxHitsPerPage"  => "25",
          "id_swissreg:mainContent:id_cbxTMColorClaim" => "_ALL",
          "id_swissreg:mainContent:id_cbxTMForm"       => "_ALL",
          "id_swissreg:mainContent:id_cbxTMTypeGrp"    => "_ALL",
          "id_swissreg:mainContent:id_ckbTMChoice"     => "tm_lbl_applicant",
          "id_swissreg:mainContent:id_ckbTMPubReason"  => "8",
          "id_swissreg:mainContent:id_ckbTMState"      => "3",
          "id_swissreg:mainContent:id_txf_agent"       => "",
          "id_swissreg:mainContent:id_txf_appDate"     => "",
          "id_swissreg:mainContent:id_txf_app_no"      => "",
          "id_swissreg:mainContent:id_txf_applicant"   => "",
          "id_swissreg:mainContent:id_txf_expiryDate"  => "",
          "id_swissreg:mainContent:id_txf_licensee"    => "",
          "id_swissreg:mainContent:id_txf_nizza_class" => "",
          "id_swissreg:mainContent:id_txf_pub_date"    => "",
          "id_swissreg:mainContent:id_txf_tm_no"       => "",
          "id_swissreg:mainContent:id_txf_tm_text"     => "",
          "id_swissreg_SUBMIT"                         => "1",
          "javax.faces.ViewState"                      => "rO0ABXVyABNbTGphdmEubGFuZy5PYmplY3Q7kM5YnxBzKWwCAAB4cAAAAAN0AAEzcHQAFi9qc3AvdHJhZGVtYXJrL3NyMy5qc3A="
        }).
      to_return(
        :status  => 200,
        :headers => {"Content-Type" => 'text/html; charset=utf-8'},
        :body    => stub_response)
      
    counter = 0
    trademark_ids.each{ 
      |trademark_id|
      counter += 1
      filename = File.expand_path("../../data/#{result_folder}/detail_#{sprintf('%05i',counter)}_#{trademark_id.sub('/','.')}.html", __FILE__)
      stub_response = File.read(filename)
      stub_request(:get, "https://www.swissreg.ch/srclient/faces/jsp/trademark/sr300.jsp?language=de&section=tm&id=#{trademark_id}").
        with(
          :headers => {
            "Accept" => "*/*",
            "Host"   => "www.swissreg.ch",
          }).
        to_return(
          :status  => 200,
          :headers => {"Content-Type" => 'text/html; charset=utf-8'},
          :body    => stub_response)

    }
    stub_request(:post, "https://www.swissreg.ch/srclient/faces/jsp/trademark/sr30.jsp").
    with(:body => {"autoScroll"=>"", "id_swissreg:_idcl"=>"", "id_swissreg:_link_hidden_"=>"", "id_swissreg:mainContent:id_sub_options_result:id_ckbTMChoice"=>"tm_lbl_app_date", "id_swissreg:mainContent:id_sub_options_result:sub_fieldset:id_cbxHitsPerPage"=>"250", "id_swissreg:mainContent:scroll_1"=>"",
                   "id_swissreg:mainContent:vivian"=>
                  "TRADEMARK REGISTER SEARCH TIMES: QUERY=[14] SELECT=[20] SERVER=[37] DELEGATE=[46]", "id_swissreg_SUBMIT"=>"1", "javax.faces.ViewState"=>"rO0ABXVyABNbTGphdmEubGFuZy5PYmplY3Q7kM5YnxBzKWwCAAB4cAAAAAN0AAE0cHQAFy9qc3AvdHJhZGVtYXJrL3NyMzAuanNw", "tmMainId"=>""}
          ).
      to_return(:status => 200, :body => "", :headers => {})

  end
 
end
