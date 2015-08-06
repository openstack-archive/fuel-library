#! /usr/bin/env ruby
require 'spec_helper'

require 'puppet/util/network_device/ipcalc'

describe Puppet::Util::NetworkDevice::IPCalc do
  class TestIPCalc
    include Puppet::Util::NetworkDevice::IPCalc
  end

  before(:each) do
    @ipcalc = TestIPCalc.new
  end

  describe "when parsing ip/prefix" do
    it "should parse ipv4 without prefixes" do
      @ipcalc.parse('127.0.0.1').should == [32,IPAddr.new('127.0.0.1')]
    end

    it "should parse ipv4 with prefixes" do
      @ipcalc.parse('127.0.1.2/8').should == [8,IPAddr.new('127.0.1.2')]
    end

    it "should parse ipv6 without prefixes" do
      @ipcalc.parse('FE80::21A:2FFF:FE30:ECF0').should == [128,IPAddr.new('FE80::21A:2FFF:FE30:ECF0')]
    end

    it "should parse ipv6 with prefixes" do
      @ipcalc.parse('FE80::21A:2FFF:FE30:ECF0/56').should == [56,IPAddr.new('FE80::21A:2FFF:FE30:ECF0')]
    end
  end

  describe "when building netmask" do
    it "should produce the correct ipv4 netmask from prefix length" do
      @ipcalc.netmask(Socket::AF_INET, 27).should == IPAddr.new('255.255.255.224')
    end

    it "should produce the correct ipv6 netmask from prefix length" do
      @ipcalc.netmask(Socket::AF_INET6, 56).should == IPAddr.new('ffff:ffff:ffff:ff00::0')
    end
  end

  describe "when building wildmask" do
    it "should produce the correct ipv4 wildmask from prefix length" do
      @ipcalc.wildmask(Socket::AF_INET, 27).should == IPAddr.new('0.0.0.31')
    end

    it "should produce the correct ipv6 wildmask from prefix length" do
      @ipcalc.wildmask(Socket::AF_INET6, 126).should == IPAddr.new('::3')
    end
  end

  describe "when computing prefix length from netmask" do
    it "should produce the correct ipv4 prefix length" do
      @ipcalc.prefix_length(IPAddr.new('255.255.255.224')).should == 27
    end

    it "should produce the correct ipv6 prefix length" do
      @ipcalc.prefix_length(IPAddr.new('fffe::0')).should == 15
    end
  end
end
