# encoding : utf-8 
require "spec_helper"

require 'stringio'
require 'ostruct'

module Kernel
  # for stdout/stderr
  def capture(stream)
    begin
      stream = stream.to_s
      eval "$#{stream} = StringIO.new"
      yield
      result = eval("$#{stream}").string
    ensure
      eval "$#{stream} = #{stream.upcase}"
    end
    result
  end
  # for load executable
  def exit(status=false)
    raise Interrupt
  end
end

begin
  capture(:stdout) { load File.expand_path("../../bin/brand2csv", __FILE__) }
rescue Interrupt
end

describe Brand2csv do
  describe "#validates_timespan" do
    subject { validates_timespan(arg) }

    context "when timespan is a single date" do
      context "when invalid last day of month in a date is given" do
        let(:arg) { "29.02.2010" }
        it { should eql [false, "Did you mean 28.02.2010 ?"] }
      end

      context "when invalid month in a date is given" do
        let(:arg) { "28.13.2010" }
        it { should eql [false, "Timespan is invalid"] }
      end

      context "when a valid date is given" do
        let(:arg) { "31.12.2010" }
        it { should eql [true, nil] }
      end
    end

    context "when timespan is term" do
      context "when invalid last day of month in start date is given" do
        let(:arg) { "29.02.2010-31.03.2010" }
        it { should eql [false, "Did you mean 28.02.2010-31.03.2010 ?"] }
      end

      context "when invalid last day of month in end date is given" do
        let(:arg) { "28.04.2010-99.03.2010" }
        it { should eql [false, "Did you mean 28.04.2010-31.03.2010 ?"] }
      end

      context "when invalid last day of month in both dates is given" do
        let(:arg) { "32.01.2010-99.05.2010" }
        it { should eql [false, "Did you mean 31.01.2010-31.05.2010 ?"] }
      end

      context "when invalid month in start date is given" do
        let(:arg) { "31.99.2010-31.05.2010" }
        it { should eql [false, "Timespan is invalid"] }
      end

      context "when invalid month in end date is given" do
        let(:arg) { "31.01.2010-31.20.2010" }
        it { should eql [false, "Timespan is invalid"] }
      end

      context "when invalid month in both dates is given" do
        let(:arg) { "31.30.2010-31.20.2010" }
        it { should eql [false, "Timespan is invalid"] }
      end

      context "when valid term is given" do
        let(:arg) { "28.02.2010-31.05.2010" }
        it { should eql [true, nil] }
      end
    end
  end
end
