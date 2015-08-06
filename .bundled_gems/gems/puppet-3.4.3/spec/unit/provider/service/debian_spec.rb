#! /usr/bin/env ruby
#
# Unit testing for the debian service provider
#

require 'spec_helper'

provider_class = Puppet::Type.type(:service).provider(:debian)

describe provider_class do

  before(:each) do
    # Create a mock resource
    @resource = stub 'resource'

    @provider = provider_class.new

    # A catch all; no parameters set
    @resource.stubs(:[]).returns(nil)

    # But set name, source and path
    @resource.stubs(:[]).with(:name).returns "myservice"
    @resource.stubs(:[]).with(:ensure).returns :enabled
    @resource.stubs(:ref).returns "Service[myservice]"

    @provider.resource = @resource

    @provider.stubs(:command).with(:update_rc).returns "update_rc"
    @provider.stubs(:command).with(:invoke_rc).returns "invoke_rc"

    @provider.stubs(:update_rc)
    @provider.stubs(:invoke_rc)
  end

  it "should have an enabled? method" do
    @provider.should respond_to(:enabled?)
  end

  it "should have an enable method" do
    @provider.should respond_to(:enable)
  end

  it "should have a disable method" do
    @provider.should respond_to(:disable)
  end

  describe "when enabling" do
    it "should call update-rc.d twice" do
      @provider.expects(:update_rc).twice
      @provider.enable
    end
  end

  describe "when disabling" do
    it "should be able to disable services with newer sysv-rc versions" do
      @provider.stubs(:`).with("dpkg --compare-versions $(dpkg-query -W --showformat '${Version}' sysv-rc) ge 2.88 ; echo $?").returns "0"

      @provider.expects(:update_rc).with(@resource[:name], "disable")

      @provider.disable
    end

    it "should be able to enable services with older sysv-rc versions" do
      @provider.stubs(:`).with("dpkg --compare-versions $(dpkg-query -W --showformat '${Version}' sysv-rc) ge 2.88 ; echo $?").returns "1"

      @provider.expects(:update_rc).with("-f", @resource[:name], "remove")
      @provider.expects(:update_rc).with(@resource[:name], "stop", "00", "1", "2", "3", "4", "5", "6", ".")

      @provider.disable
    end
  end

  describe "when checking whether it is enabled" do
    it "should call Kernel.system() with the appropriate parameters" do
      @provider.expects(:system).with("/usr/sbin/invoke-rc.d", "--quiet", "--query", @resource[:name], "start").once
      @provider.enabled?
    end

    it "should return true when invoke-rc.d exits with 104 status" do
      @provider.stubs(:system)
      $CHILD_STATUS.stubs(:exitstatus).returns(104)
      @provider.enabled?.should == :true
    end

    it "should return true when invoke-rc.d exits with 106 status" do
      @provider.stubs(:system)
      $CHILD_STATUS.stubs(:exitstatus).returns(106)
      @provider.enabled?.should == :true
    end

    context "when invoke-rc.d exits with 105 status" do
      it "links count is 4" do
        @provider.stubs(:system)
        $CHILD_STATUS.stubs(:exitstatus).returns(105)
        @provider.stubs(:get_start_link_count).returns(4)
        @provider.enabled?.should == :true
      end
      it "links count is less than 4" do
        @provider.stubs(:system)
        $CHILD_STATUS.stubs(:exitstatus).returns(105)
        @provider.stubs(:get_start_link_count).returns(3)
        @provider.enabled?.should == :false
      end
    end

    # pick a range of non-[104.106] numbers, strings and booleans to test with.
    [-100, -1, 0, 1, 100, "foo", "", :true, :false].each do |exitstatus|
      it "should return false when invoke-rc.d exits with #{exitstatus} status" do
        @provider.stubs(:system)
        $CHILD_STATUS.stubs(:exitstatus).returns(exitstatus)
        @provider.enabled?.should == :false
      end
    end
  end

end
