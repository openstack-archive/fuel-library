#! /usr/bin/env ruby
require 'spec_helper'

require 'puppet/indirector/yaml'

describe Puppet::Indirector::Yaml do
  include PuppetSpec::Files

  class TestSubject
    attr_accessor :name
  end

  before :all do
    @indirection = stub 'indirection', :name => :my_yaml, :register_terminus_type => nil
    Puppet::Indirector::Indirection.expects(:instance).with(:my_yaml).returns(@indirection)
    module MyYaml; end
    @store_class = class MyYaml::MyType < Puppet::Indirector::Yaml
      self
    end
  end

  before :each do
    @store = @store_class.new

    @subject = TestSubject.new
    @subject.name = :me

    @dir = tmpdir("yaml_indirector")
    Puppet[:clientyamldir] = @dir
    Puppet.run_mode.stubs(:master?).returns false

    @request = stub 'request', :key => :me, :instance => @subject
  end

  let(:serverdir) { File.expand_path("/server/yaml/dir") }
  let(:clientdir) { File.expand_path("/client/yaml/dir") }

  describe "when choosing file location" do
    it "should use the server_datadir if the run_mode is master" do
      Puppet.run_mode.stubs(:master?).returns true
      Puppet[:yamldir] = serverdir
      @store.path(:me).should =~ /^#{serverdir}/
    end

    it "should use the client yamldir if the run_mode is not master" do
      Puppet.run_mode.stubs(:master?).returns false
      Puppet[:clientyamldir] = clientdir
      @store.path(:me).should =~ /^#{clientdir}/
    end

    it "should use the extension if one is specified" do
      Puppet.run_mode.stubs(:master?).returns true
      Puppet[:yamldir] = serverdir
      @store.path(:me,'.farfignewton').should =~ %r{\.farfignewton$}
    end

    it "should assume an extension of .yaml if none is specified" do
      Puppet.run_mode.stubs(:master?).returns true
      Puppet[:yamldir] = serverdir
      @store.path(:me).should =~ %r{\.yaml$}
    end

    it "should store all files in a single file root set in the Puppet defaults" do
      @store.path(:me).should =~ %r{^#{@dir}}
    end

    it "should use the terminus name for choosing the subdirectory" do
      @store.path(:me).should =~ %r{^#{@dir}/my_yaml}
    end

    it "should use the object's name to determine the file name" do
      @store.path(:me).should =~ %r{me.yaml$}
    end

    ['../foo', '..\\foo', './../foo', '.\\..\\foo',
     '/foo', '//foo', '\\foo', '\\\\goo',
     "test\0/../bar", "test\0\\..\\bar",
     "..\\/bar", "/tmp/bar", "/tmp\\bar", "tmp\\bar",
     " / bar", " /../ bar", " \\..\\ bar",
     "c:\\foo", "c:/foo", "\\\\?\\UNC\\bar", "\\\\foo\\bar",
     "\\\\?\\c:\\foo", "//?/UNC/bar", "//foo/bar",
     "//?/c:/foo",
    ].each do |input|
      it "should resist directory traversal attacks (#{input.inspect})" do
        expect { @store.path(input) }.to raise_error
      end
    end
  end

  describe "when storing objects as YAML" do
    it "should only store objects that respond to :name" do
      @request.stubs(:instance).returns Object.new
      proc { @store.save(@request) }.should raise_error(ArgumentError)
    end
  end

  describe "when retrieving YAML" do
    it "should read YAML in from disk and convert it to Ruby objects" do
      @store.save(Puppet::Indirector::Request.new(:my_yaml, :save, "testing", @subject))

      @store.find(Puppet::Indirector::Request.new(:my_yaml, :find, "testing", nil)).name.should == :me
    end

    it "should fail coherently when the stored YAML is invalid" do
      saved_structure = Struct.new(:name).new("testing")

      @store.save(Puppet::Indirector::Request.new(:my_yaml, :save, "testing", saved_structure))
      File.open(@store.path(saved_structure.name), "w") do |file|
        file.puts "{ invalid"
      end

      expect {
        @store.find(Puppet::Indirector::Request.new(:my_yaml, :find, "testing", nil))
      }.to raise_error(Puppet::Error, /Could not parse YAML data/)
    end
  end

  describe "when searching" do
    it "should return an array of fact instances with one instance for each file when globbing *" do
      @request = stub 'request', :key => "*", :instance => @subject
      @one = mock 'one'
      @two = mock 'two'
      @store.expects(:path).with(@request.key,'').returns :glob
      Dir.expects(:glob).with(:glob).returns(%w{one.yaml two.yaml})
      YAML.expects(:load_file).with("one.yaml").returns @one;
      YAML.expects(:load_file).with("two.yaml").returns @two;
      @store.search(@request).should == [@one, @two]
    end

    it "should return an array containing a single instance of fact when globbing 'one*'" do
      @request = stub 'request', :key => "one*", :instance => @subject
      @one = mock 'one'
      @store.expects(:path).with(@request.key,'').returns :glob
      Dir.expects(:glob).with(:glob).returns(%w{one.yaml})
      YAML.expects(:load_file).with("one.yaml").returns @one;
      @store.search(@request).should == [@one]
    end

    it "should return an empty array when the glob doesn't match anything" do
      @request = stub 'request', :key => "f*ilglobcanfail*", :instance => @subject
      @store.expects(:path).with(@request.key,'').returns :glob
      Dir.expects(:glob).with(:glob).returns []
      @store.search(@request).should == []
    end

    describe "when destroying" do
      let(:path) do
        File.join(@dir, @store.class.indirection_name.to_s, @request.key.to_s + ".yaml")
      end

      it "should unlink the right yaml file if it exists" do
        Puppet::FileSystem::File.expects(:exist?).with(path).returns true
        Puppet::FileSystem::File.expects(:unlink).with(path)

        @store.destroy(@request)
      end

      it "should not unlink the yaml file if it does not exists" do
        Puppet::FileSystem::File.expects(:exist?).with(path).returns false
        Puppet::FileSystem::File.expects(:unlink).with(path).never

        @store.destroy(@request)
      end
    end
  end
end
