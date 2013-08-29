#!/usr/bin/env ruby
# encoding: utf-8

require 'rubygems'
require 'hoe'

Hoe.spec "brand2csv" do
  self.author      = "Niklaus Giger, Yasuhiro Asaka, Zeno R.R. Davatz" # gem.authors
  self.email       = "ngiger@ywesee.com, yasaka@ywesee.com, zdavatz@ywesee.com"
  self.description = "brand2csv creates csv files for swiss brand registered in a specific time period. 
  The csv contains the brand, link to image (if present), link to the detailinfo at swissreg.ch, name and address of owner (Inhaber)"
  self.summary     = "brand2csv creates csv files for swiss brands."
  self.urls        = ["https://github.com/zdavatz/brand2csv"] # gem.homepage
  self.license     = "GPLv3.0"
  # gem.add_runtime_dependency
  self.extra_deps << ['mechanize', '>= 2.6']

  # gem.add_development_dependency
  self.extra_dev_deps << ['rspec']
  self.extra_dev_deps << ['webmock']
  self.extra_dev_deps << ['hoe', '>= 3.4']
  self.extra_dev_deps << ['rdoc']
end
