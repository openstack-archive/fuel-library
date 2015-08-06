require "spec_helper"
require "puppet/version"
require 'pathname'

describe "Puppet.version Public API" do
  before :each do
    Puppet.instance_eval do
      if @puppet_version
        @puppet_version = nil
      end
    end
  end

  context "without a VERSION file" do
    before :each do
      Puppet.stubs(:read_version_file).returns(nil)
    end

    it "is Puppet::PUPPETVERSION" do
      Puppet.version.should == Puppet::PUPPETVERSION
    end
    it "respects the version= setter" do
      Puppet.version = '1.2.3'
      Puppet.version.should == '1.2.3'
    end
  end

  context "with a VERSION file" do
    it "is the content of the file" do
      Puppet.expects(:read_version_file).with() do |path|
        pathname = Pathname.new(path)
        pathname.basename.to_s == "VERSION"
      end.returns('3.0.1-260-g9ca4e54')

      Puppet.version.should == '3.0.1-260-g9ca4e54'
    end
    it "respects the version= setter" do
      Puppet.version = '1.2.3'
      Puppet.version.should == '1.2.3'
    end
  end
end
