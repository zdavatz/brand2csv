# encoding: utf-8
$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$:.unshift File.dirname(__FILE__)

require 'bundler/setup'
Bundler.require

require 'rspec'
require "webmock/rspec"

Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each { |f| require f }

require 'brand2csv'
begin
  capture(:stdout) { load File.expand_path("../../bin/brand2csv", __FILE__) }
rescue LoadError
end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.filter_run_excluding :slow
  #config.exclusion_filter = {:slow => true}

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  # Helper
  config.include(ServerMockHelper)
end
