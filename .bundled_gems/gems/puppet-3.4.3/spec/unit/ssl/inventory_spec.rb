#! /usr/bin/env ruby
require 'spec_helper'

require 'puppet/ssl/inventory'

describe Puppet::SSL::Inventory, :unless => Puppet.features.microsoft_windows? do
  let(:cert_inventory) { File.expand_path("/inven/tory") }
  before do
    @class = Puppet::SSL::Inventory
  end

  describe "when initializing" do
    it "should set its path to the inventory file" do
      Puppet[:cert_inventory] = cert_inventory
      @class.new.path.should == cert_inventory
    end
  end

  describe "when managing an inventory" do
    before do
      Puppet[:cert_inventory] = cert_inventory

      Puppet::FileSystem::File.stubs(:exist?).with(cert_inventory).returns true

      @inventory = @class.new

      @cert = mock 'cert'
    end

    describe "and creating the inventory file" do
      it "re-adds all of the existing certificates" do
        inventory_file = StringIO.new
        Puppet.settings.setting(:cert_inventory).stubs(:open).yields(inventory_file)

        cert1 = Puppet::SSL::Certificate.new("cert1")
        cert1.content = stub 'cert1',
          :serial => 2,
          :not_before => Time.now,
          :not_after => Time.now,
          :subject => "/CN=smocking"
        cert2 = Puppet::SSL::Certificate.new("cert2")
        cert2.content = stub 'cert2',
          :serial => 3,
          :not_before => Time.now,
          :not_after => Time.now,
          :subject => "/CN=mocking bird"
        Puppet::SSL::Certificate.indirection.expects(:search).with("*").returns [cert1, cert2]

        @inventory.rebuild

        expect(inventory_file.string).to match(/\/CN=smocking/)
        expect(inventory_file.string).to match(/\/CN=mocking bird/)
      end
    end

    describe "and adding a certificate" do

      it "should use the Settings to write to the file" do
        Puppet.settings.setting(:cert_inventory).expects(:open).with("a")

        @inventory.add(@cert)
      end

      it "should add formatted certificate information to the end of the file" do
        cert = Puppet::SSL::Certificate.new("mycert")
        cert.content = @cert

        fh = StringIO.new
        Puppet.settings.setting(:cert_inventory).expects(:open).with("a").yields(fh)

        @inventory.expects(:format).with(@cert).returns "myformat"

        @inventory.add(@cert)

        expect(fh.string).to eq("myformat")
      end
    end

    describe "and formatting a certificate" do
      before do
        @cert = stub 'cert', :not_before => Time.now, :not_after => Time.now, :subject => "mycert", :serial => 15
      end

      it "should print the serial number as a 4 digit hex number in the first field" do
        @inventory.format(@cert).split[0].should == "0x000f" # 15 in hex
      end

      it "should print the not_before date in '%Y-%m-%dT%H:%M:%S%Z' format in the second field" do
        @cert.not_before.expects(:strftime).with('%Y-%m-%dT%H:%M:%S%Z').returns "before_time"

        @inventory.format(@cert).split[1].should == "before_time"
      end

      it "should print the not_after date in '%Y-%m-%dT%H:%M:%S%Z' format in the third field" do
        @cert.not_after.expects(:strftime).with('%Y-%m-%dT%H:%M:%S%Z').returns "after_time"

        @inventory.format(@cert).split[2].should == "after_time"
      end

      it "should print the subject in the fourth field" do
        @inventory.format(@cert).split[3].should == "mycert"
      end

      it "should add a carriage return" do
        @inventory.format(@cert).should =~ /\n$/
      end

      it "should produce a line consisting of the serial number, start date, expiration date, and subject" do
        # Just make sure our serial and subject bracket the lines.
        @inventory.format(@cert).should =~ /^0x.+mycert$/
      end
    end

    it "should be able to find a given host's serial number" do
      @inventory.should respond_to(:serial)
    end

    describe "and finding a serial number" do
      it "should return nil if the inventory file is missing" do
        Puppet::FileSystem::File.expects(:exist?).with(cert_inventory).returns false
        @inventory.serial(:whatever).should be_nil
      end

      it "should return the serial number from the line matching the provided name" do
        File.expects(:readlines).with(cert_inventory).returns ["0x00f blah blah /CN=me\n", "0x001 blah blah /CN=you\n"]

        @inventory.serial("me").should == 15
      end

      it "should return the number as an integer" do
        File.expects(:readlines).with(cert_inventory).returns ["0x00f blah blah /CN=me\n", "0x001 blah blah /CN=you\n"]

        @inventory.serial("me").should == 15
      end
    end
  end
end
