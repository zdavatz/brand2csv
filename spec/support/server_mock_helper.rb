#!/usr/bin/env ruby
# encoding: utf-8

module ServerMockHelper
  def setup_swissreg_ch_server
    # main
    stub_html_url = "https://www.swissreg.ch/srclient/faces/jsp/start.jsp"
    stub_response = File.read(File.expand_path("../../data/main.html", __FILE__))
    stub_request(:get, stub_html_url).
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
    stub_html_url = "https://www.swissreg.ch/srclient/faces/jsp/start.jsp"
    stub_response = File.read(File.expand_path("../../data/erweiterte_suche.html", __FILE__))
    stub_request(:post, stub_html_url).
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
    stub_html_url = "https://www.swissreg.ch/srclient/faces/jsp/trademark/sr3.jsp"
    stub_response = File.read(File.expand_path("../../data/result_2_marken.html", __FILE__))
    stub_request(:post, stub_html_url).
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
          "id_swissreg:mainContent:id_txf_appDate"         => "01.01.2012-31.12.2012",
          "id_swissreg:mainContent:id_txf_app_no"          => "",
          "id_swissreg:mainContent:id_txf_applicant"       => "",
          "id_swissreg:mainContent:id_txf_expiryDate"      => "",
          "id_swissreg:mainContent:id_txf_licensee"        => "",
          "id_swissreg:mainContent:id_txf_nizza_class"     => "",
          "id_swissreg:mainContent:id_txf_pub_date"        => "",
          "id_swissreg:mainContent:id_txf_tm_no"           => "",
          "id_swissreg:mainContent:id_txf_tm_text"         => "aspectra*",
          "id_swissreg:mainContent:sub_fieldset:id_submit" => "suchen",
          "id_swissreg_SUBMIT"                             => "1",
          "javax.faces.ViewState"                          => "rO0ABXVyABNbTGphdmEubGFuZy5PYmplY3Q7kM5YnxBzKWwCAAB4cAAAAAN0AAExcHQADi9qc3Avc3RhcnQuanNw"
        }).
      to_return(
        :status  => 200,
        :headers => {"Content-Type" => 'text/html; charset=utf-8'},
        :body    => stub_response)
    # result page 2
    stub_html_url = "https://www.swissreg.ch/srclient/faces/jsp/trademark/sr3.jsp"
    stub_response = File.read(File.expand_path("../../data/result_2_marken.html", __FILE__))
    stub_request(:post, stub_html_url).
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
    # product 1 of aspectra*
    stub_html_url = "https://www.swissreg.ch/srclient/faces/jsp/trademark/sr300.jsp?language=de&section=tm&id=P-480296"
    stub_response = File.read(File.expand_path("../../data/detail_00001_P-480296.html", __FILE__))
    stub_request(:get, stub_html_url).
      with(
        :headers => {
          "Accept" => "*/*",
          "Host"   => "www.swissreg.ch",
        }).
      to_return(
        :status  => 200,
        :headers => {"Content-Type" => 'text/html; charset=utf-8'},
        :body    => stub_response)
    # product 2 of aspectra*
    stub_html_url = "https://www.swissreg.ch/srclient/faces/jsp/trademark/sr300.jsp?language=de&section=tm&id=P-482236"
    stub_response = File.read(File.expand_path("../../data/detail_00002_P-482236.html", __FILE__))
    stub_request(:get, stub_html_url).
      with(
        :headers => {
          "Accept" => "*/*",
          "Host"   => "www.swissreg.ch",
        }).
      to_return(
        :status  => 200,
        :headers => {"Content-Type" => 'text/html; charset=utf-8'},
        :body    => stub_response)
  end
end
