#! /usr/bin/env ruby
require 'spec_helper'

require 'puppet/file_serving/configuration'

describe Puppet::FileServing::Configuration do
  include PuppetSpec::Files

  before :each do
    @path = make_absolute("/path/to/configuration/file.conf")
    Puppet[:trace] = false
    Puppet[:fileserverconfig] = @path
  end

  after :each do
    Puppet::FileServing::Configuration.instance_variable_set(:@configuration, nil)
  end

  it "should make :new a private method" do
    expect { Puppet::FileServing::Configuration.new }.to raise_error
  end

  it "should return the same configuration each time 'configuration' is called" do
    Puppet::FileServing::Configuration.configuration.should equal(Puppet::FileServing::Configuration.configuration)
  end

  describe "when initializing" do

    it "should work without a configuration file" do
      Puppet::FileSystem::File.stubs(:exist?).with(@path).returns(false)
      expect { Puppet::FileServing::Configuration.configuration }.to_not raise_error
    end

    it "should parse the configuration file if present" do
      Puppet::FileSystem::File.stubs(:exist?).with(@path).returns(true)
      @parser = mock 'parser'
      @parser.expects(:parse).returns({})
      Puppet::FileServing::Configuration::Parser.stubs(:new).returns(@parser)
      Puppet::FileServing::Configuration.configuration
    end

    it "should determine the path to the configuration file from the Puppet settings" do
      Puppet::FileServing::Configuration.configuration
    end
  end

  describe "when parsing the configuration file" do

    before do
      Puppet::FileSystem::File.stubs(:exist?).with(@path).returns(true)
      @parser = mock 'parser'
      Puppet::FileServing::Configuration::Parser.stubs(:new).returns(@parser)
    end

    it "should set the mount list to the results of parsing" do
      @parser.expects(:parse).returns("one" => mock("mount"))
      config = Puppet::FileServing::Configuration.configuration
      config.mounted?("one").should be_true
    end

    it "should not raise exceptions" do
      @parser.expects(:parse).raises(ArgumentError)
      expect { Puppet::FileServing::Configuration.configuration }.to_not raise_error
    end

    it "should replace the existing mount list with the results of reparsing" do
      @parser.expects(:parse).returns("one" => mock("mount"))
      config = Puppet::FileServing::Configuration.configuration
      config.mounted?("one").should be_true
      # Now parse again
      @parser.expects(:parse).returns("two" => mock('other'))
      config.send(:readconfig, false)
      config.mounted?("one").should be_false
      config.mounted?("two").should be_true
    end

    it "should not replace the mount list until the file is entirely parsed successfully" do
      @parser.expects(:parse).returns("one" => mock("mount"))
      @parser.expects(:parse).raises(ArgumentError)
      config = Puppet::FileServing::Configuration.configuration
      # Now parse again, so the exception gets thrown
      config.send(:readconfig, false)
      config.mounted?("one").should be_true
    end

    it "should add modules and plugins mounts even if the file does not exist" do
      Puppet::FileSystem::File.expects(:exist?).returns false # the file doesn't exist
      config = Puppet::FileServing::Configuration.configuration
      config.mounted?("modules").should be_true
      config.mounted?("plugins").should be_true
    end

    it "should allow all access to modules and plugins if no fileserver.conf exists" do
      Puppet::FileSystem::File.expects(:exist?).returns false # the file doesn't exist
      modules = stub 'modules', :empty? => true
      Puppet::FileServing::Mount::Modules.stubs(:new).returns(modules)
      modules.expects(:allow).with('*')

      plugins = stub 'plugins', :empty? => true
      Puppet::FileServing::Mount::Plugins.stubs(:new).returns(plugins)
      plugins.expects(:allow).with('*')

      Puppet::FileServing::Configuration.configuration
    end

    it "should not allow access from all to modules and plugins if the fileserver.conf provided some rules" do
      Puppet::FileSystem::File.expects(:exist?).returns false # the file doesn't exist

      modules = stub 'modules', :empty? => false
      Puppet::FileServing::Mount::Modules.stubs(:new).returns(modules)
      modules.expects(:allow).with('*').never

      plugins = stub 'plugins', :empty? => false
      Puppet::FileServing::Mount::Plugins.stubs(:new).returns(plugins)
      plugins.expects(:allow).with('*').never

      Puppet::FileServing::Configuration.configuration
    end

    it "should add modules and plugins mounts even if they are not returned by the parser" do
      @parser.expects(:parse).returns("one" => mock("mount"))
      Puppet::FileSystem::File.expects(:exist?).returns true # the file doesn't exist
      config = Puppet::FileServing::Configuration.configuration
      config.mounted?("modules").should be_true
      config.mounted?("plugins").should be_true
    end
  end

  describe "when finding the specified mount" do
    it "should choose the named mount if one exists" do
      config = Puppet::FileServing::Configuration.configuration
      config.expects(:mounts).returns("one" => "foo")
      config.find_mount("one", mock('env')).should == "foo"
    end

    it "should return nil if there is no such named mount" do
      config = Puppet::FileServing::Configuration.configuration

      env = mock 'environment'
      mount = mock 'mount'
      config.stubs(:mounts).returns("modules" => mount)

      config.find_mount("foo", env).should be_nil
    end
  end

  describe "#split_path" do
    let(:config) { Puppet::FileServing::Configuration.configuration }
    let(:request) { stub 'request', :key => "foo/bar/baz", :options => {}, :node => nil, :environment => mock("env") }

    before do
      config.stubs(:find_mount)
    end

    it "should reread the configuration" do
      config.expects(:readconfig)

      config.split_path(request)
    end

    it "should treat the first field of the URI path as the mount name" do
      config.expects(:find_mount).with { |name, node| name == "foo" }

      config.split_path(request)
    end

    it "should fail if the mount name is not alpha-numeric" do
      request.expects(:key).returns "foo&bar/asdf"

      expect { config.split_path(request) }.to raise_error(ArgumentError)
    end

    it "should support dashes in the mount name" do
      request.expects(:key).returns "foo-bar/asdf"

      expect { config.split_path(request) }.to_not raise_error
    end

    it "should use the mount name and environment to find the mount" do
      config.expects(:find_mount).with { |name, env| name == "foo" and env == request.environment }
      request.stubs(:node).returns("mynode")

      config.split_path(request)
    end

    it "should return nil if the mount cannot be found" do
      config.expects(:find_mount).returns nil

      config.split_path(request).should be_nil
    end

    it "should return the mount and the relative path if the mount is found" do
      mount = stub 'mount', :name => "foo"
      config.expects(:find_mount).returns mount

      config.split_path(request).should == [mount, "bar/baz"]
    end

    it "should remove any double slashes" do
      request.stubs(:key).returns "foo/bar//baz"
      mount = stub 'mount', :name => "foo"
      config.expects(:find_mount).returns mount

      config.split_path(request).should == [mount, "bar/baz"]
    end

    it "should fail if the path contains .." do
      request.stubs(:key).returns 'module/foo/../../bar'

      expect do
        config.split_path(request)
      end.to raise_error(ArgumentError, /Invalid relative path/)
    end

    it "should return the relative path as nil if it is an empty string" do
      request.expects(:key).returns "foo"
      mount = stub 'mount', :name => "foo"
      config.expects(:find_mount).returns mount

      config.split_path(request).should == [mount, nil]
    end

    it "should add 'modules/' to the relative path if the modules mount is used but not specified, for backward compatibility" do
      request.expects(:key).returns "foo/bar"
      mount = stub 'mount', :name => "modules"
      config.expects(:find_mount).returns mount

      config.split_path(request).should == [mount, "foo/bar"]
    end
  end
end
