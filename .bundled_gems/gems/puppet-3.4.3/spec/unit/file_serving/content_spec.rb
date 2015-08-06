#! /usr/bin/env ruby
require 'spec_helper'

require 'puppet/file_serving/content'

describe Puppet::FileServing::Content do
  let(:path) { File.expand_path('/path') }

  it "should be a subclass of Base" do
    Puppet::FileServing::Content.superclass.should equal(Puppet::FileServing::Base)
  end

  it "should indirect file_content" do
    Puppet::FileServing::Content.indirection.name.should == :file_content
  end

  it "should only support the raw format" do
    Puppet::FileServing::Content.supported_formats.should == [:raw]
  end

  it "should have a method for collecting its attributes" do
    Puppet::FileServing::Content.new(path).should respond_to(:collect)
  end

  it "should not retrieve and store its contents when its attributes are collected if the file is a normal file" do
    content = Puppet::FileServing::Content.new(path)

    result = "foo"
    stub_file = stub(path, :lstat => stub('stat', :ftype => "file"))
    Puppet::FileSystem::File.expects(:new).with(path).returns stub_file
    File.expects(:read).with(path).never
    content.collect

    content.instance_variable_get("@content").should be_nil
  end

  it "should not attempt to retrieve its contents if the file is a directory" do
    content = Puppet::FileServing::Content.new(path)

    result = "foo"
    stub_file = stub(path, :lstat => stub('stat', :ftype => "directory"))
    Puppet::FileSystem::File.expects(:new).with(path).returns stub_file
    File.expects(:read).with(path).never
    content.collect

    content.instance_variable_get("@content").should be_nil
  end

  it "should have a method for setting its content" do
    content = Puppet::FileServing::Content.new(path)
    content.should respond_to(:content=)
  end

  it "should make content available when set externally" do
    content = Puppet::FileServing::Content.new(path)
    content.content = "foo/bar"
    content.content.should == "foo/bar"
  end

  it "should be able to create a content instance from raw file contents" do
    Puppet::FileServing::Content.should respond_to(:from_raw)
  end

  it "should create an instance with a fake file name and correct content when converting from raw" do
    instance = mock 'instance'
    Puppet::FileServing::Content.expects(:new).with("/this/is/a/fake/path").returns instance

    instance.expects(:content=).with "foo/bar"

    Puppet::FileServing::Content.from_raw("foo/bar").should equal(instance)
  end

  it "should return an opened File when converted to raw" do
    content = Puppet::FileServing::Content.new(path)

    File.expects(:new).with(path, "rb").returns :file

    content.to_raw.should == :file
  end
end

describe Puppet::FileServing::Content, "when returning the contents" do
  let(:path) { File.expand_path('/my/path') }
  let(:content) { Puppet::FileServing::Content.new(path, :links => :follow) }

  it "should fail if the file is a symlink and links are set to :manage" do
    content.links = :manage
    stub_file = stub(path, :lstat => stub("stat", :ftype => "symlink"))
    Puppet::FileSystem::File.expects(:new).with(path).returns stub_file
    proc { content.content }.should raise_error(ArgumentError)
  end

  it "should fail if a path is not set" do
    proc { content.content }.should raise_error(Errno::ENOENT)
  end

  it "should raise Errno::ENOENT if the file is absent" do
    content.path = File.expand_path("/there/is/absolutely/no/chance/that/this/path/exists")
    proc { content.content }.should raise_error(Errno::ENOENT)
  end

  it "should return the contents of the path if the file exists" do
    mocked_file = mock(path, :stat => stub('stat', :ftype => 'file'))
    Puppet::FileSystem::File.expects(:new).with(path).twice.returns(mocked_file)
    mocked_file.expects(:binread).returns(:mycontent)
    content.content.should == :mycontent
  end

  it "should cache the returned contents" do
    mocked_file = mock(path, :stat => stub('stat', :ftype => 'file'))
    Puppet::FileSystem::File.expects(:new).with(path).twice.returns(mocked_file)
    mocked_file.expects(:binread).returns(:mycontent)
    content.content
    # The second run would throw a failure if the content weren't being cached.
    content.content
  end
end
