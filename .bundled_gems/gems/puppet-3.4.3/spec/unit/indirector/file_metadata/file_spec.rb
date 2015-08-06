#! /usr/bin/env ruby
require 'spec_helper'

require 'puppet/indirector/file_metadata/file'

describe Puppet::Indirector::FileMetadata::File do
  it "should be registered with the file_metadata indirection" do
    Puppet::Indirector::Terminus.terminus_class(:file_metadata, :file).should equal(Puppet::Indirector::FileMetadata::File)
  end

  it "should be a subclass of the DirectFileServer terminus" do
    Puppet::Indirector::FileMetadata::File.superclass.should equal(Puppet::Indirector::DirectFileServer)
  end

  describe "when creating the instance for a single found file" do
    before do
      @metadata = Puppet::Indirector::FileMetadata::File.new
      @path = File.expand_path('/my/local')
      @uri = Puppet::Util.path_to_uri(@path).to_s
      @data = mock 'metadata'
      @data.stubs(:collect)
      Puppet::FileSystem::File.expects(:exist?).with(@path).returns true

      @request = Puppet::Indirector::Request.new(:file_metadata, :find, @uri, nil)
    end

    it "should collect its attributes when a file is found" do
      @data.expects(:collect)

      Puppet::FileServing::Metadata.expects(:new).returns(@data)
      @metadata.find(@request).should == @data
    end
  end

  describe "when searching for multiple files" do
    before do
      @metadata = Puppet::Indirector::FileMetadata::File.new
      @path = File.expand_path('/my/local')
      @uri = Puppet::Util.path_to_uri(@path).to_s

      @request = Puppet::Indirector::Request.new(:file_metadata, :find, @uri, nil)
    end

    it "should collect the attributes of the instances returned" do
      Puppet::FileSystem::File.expects(:exist?).with(@path).returns true
      @metadata.expects(:path2instances).returns( [mock("one", :collect => nil), mock("two", :collect => nil)] )
      @metadata.search(@request)
    end
  end
end
