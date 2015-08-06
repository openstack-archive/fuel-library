#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/file_serving/mount/pluginfacts'

describe Puppet::FileServing::Mount::PluginFacts do
  before do
    @mount = Puppet::FileServing::Mount::PluginFacts.new("pluginfacts")

    @environment = stub 'environment', :module => nil
    @options = { :recurse => true }
    @request = stub 'request', :environment => @environment, :options => @options
  end

  describe  "when finding files" do
    it "should use the provided environment to find the modules" do
      @environment.expects(:modules).returns []

      @mount.find("foo", @request)
    end

    it "should return nil if no module can be found with a matching plugin" do
      mod = mock 'module'
      mod.stubs(:pluginfact).with("foo/bar").returns nil

      @environment.stubs(:modules).returns [mod]
      @mount.find("foo/bar", @request).should be_nil
    end

    it "should return the file path from the module" do
      mod = mock 'module'
      mod.stubs(:pluginfact).with("foo/bar").returns "eh"

      @environment.stubs(:modules).returns [mod]
      @mount.find("foo/bar", @request).should == "eh"
    end
  end

  describe "when searching for files" do
    it "should use the node's environment to find the modules" do
      @environment.expects(:modules).at_least_once.returns []
      @environment.stubs(:modulepath).returns ["/tmp/modules"]

      @mount.search("foo", @request)
    end

    it "should return modulepath if no modules can be found that have plugins" do
      mod = mock 'module'
      mod.stubs(:pluginfacts?).returns false

      @environment.stubs(:modules).returns []
      @environment.stubs(:modulepath).returns ["/"]
      @options.expects(:[]=).with(:recurse, false)
      @mount.search("foo/bar", @request).should == ["/"]
    end

    it "should return nil if no modules can be found that have plugins and modulepath is invalid" do
      mod = mock 'module'
      mod.stubs(:pluginfacts?).returns false

      @environment.stubs(:modules).returns []
      @environment.stubs(:modulepath).returns []
      @mount.search("foo/bar", @request).should be_nil
    end

    it "should return the plugin paths for each module that has plugins" do
      one = stub 'module', :pluginfacts? => true, :plugin_fact_directory => "/one"
      two = stub 'module', :pluginfacts? => true, :plugin_fact_directory => "/two"

      @environment.stubs(:modules).returns [one, two]
      @mount.search("foo/bar", @request).should == %w{/one /two}
    end
  end
end
