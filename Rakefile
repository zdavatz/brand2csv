#!/usr/bin/env ruby
# encoding: utf-8

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'rake/testtask'

RSpec::Core::RakeTask.new(:spec)

desc 'Offer a gem task like hoe'
task :gem => :build do
  Rake::Task[:build].invoke
end

task :spec => :clean

require 'rake/clean'
CLEAN.include FileList['pkg/*.gem']
