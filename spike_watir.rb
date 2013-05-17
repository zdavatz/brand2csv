#!/usr/bin/env ruby
# encoding: utf-8
# require 'selenium'
require 'watir'
require 'watir-webdriver'
require 'fileutils'
require 'pp'

# zum schnell von Hand testen
# client = Selenium::WebDriver::Remote::Http::Default.new
# client.timeout = 180 # seconds – default is 60

$cnt = 1
def saveStep(b, cnt = $cnt)
  name = "watir/#{__FILE__}_#{cnt}.html".sub('.rb','')
  ausgabe = File.open(name, "w+")
  ausgabe.write(b.html)
  $cnt += 1 if $cnt.to_i != 0

end
Swiss_reg_URL = 'https://www.swissreg.ch'
client = Selenium::WebDriver::Remote::Http::Default.new
browser  = Watir::Browser.new :firefox   #, :http_client => client
# browser  = Watir::Browser.new :chrome   #, :http_client => client
browser.goto Swiss_reg_URL
#browser = Watir::Browser.start "https://www.swissreg.ch"
saveStep(browser, 11)
browser.link(:id, "id_swissreg_sub_nav_ipiNavigation_item0").click
saveStep(browser, 12 )
browser.link(:id, "id_swissreg_sub_nav_ipiNavigation_item0_item3").click
saveStep(browser, 13 )
browser.text_field(:id, "id_swissreg:mainContent:id_txf_appDate").set("1.10.2011-5.10.2011")
saveStep(browser, 14 )
browser.button(:value,"suchen").click
saveStep(browser, 15)
aus = browser.text
ausgabe=File.open('watir/liste.txt','w+')
ausgabe.puts aus
ausgabe.close
browser.link(:id, "id_swissreg:mainContent:data:2:tm_no_detail:id_detail").click# puts browser.text
browser.images.each do |x|
  idx += 1
  # apparently the string accepted by the string method will not allow variable substitution
  location = 'img_' + idx.to_s + '.png'
  x.save(location)
end
puts browser.url
pp browser.windows.each{ |w| 
                         pp w.url
#  saveStep(w)
}
# window2  = Watir::Browser.attach(:url, "https://www.swissreg.ch/srclient/faces/jsp/trademark/sr30.jsp") stackLevel too deep
#window2  = Selenium::WebDriver::Firefox.attach(:url, "https://www.swissreg.ch/srclient/faces/jsp/trademark/sr30.jsp") 
#saveStep(window2)
#aus = window2.text
ausgabe=File.open('watir/detail.txt','w+')
ausgabe.puts aus
ausgabe.close
