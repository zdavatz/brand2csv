# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'brand2csv/version'

Gem::Specification.new do |spec|
  spec.name          = "brand2csv"
  spec.version       = Brand2csv::VERSION
  spec.summary     = 'brand2csv creates csv files for swiss brands'
  spec.description = "brand2csv creates csv files for swiss brand registered in a specific time period.
  The csv contains the brand, link to image (if present), link to the detailinfo at swissreg.ch, name and address of owner (Inhaber)"
  spec.author      = 'Niklaus Giger, Yasuhiro Asaka, Zeno R.R. Davatz'
  spec.email       = 'yasaka@ywesee.com,  zdavatz@ywesee.com, ngiger@ywesee.com'
  spec.platform    = Gem::Platform::RUBY
  spec.license     = 'GPLv3'
  spec.homepage    = 'https://github.com/zdavatz/brand2csv'
  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  # gem.add_runtime_dependency
  spec.add_runtime_dependency 'mechanize', '>= 2.6'
  spec.add_runtime_dependency'json'
  spec.add_runtime_dependency'nokogiri'

  # gem.add_development_dependency
  spec.add_development_dependency 'watir'
  spec.add_development_dependency 'watir-webdriver'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rdoc'
  spec.add_development_dependency 'rspec'



  if RUBY_VERSION.match(/^1/)
    spec.add_development_dependency  'pry-debugger'
  else
    spec.add_development_dependency  'pry-byebug'
    spec.add_development_dependency  'pry-doc'
  end
end

