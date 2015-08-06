#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/file_bucket/dipper'

tidy = Puppet::Type.type(:tidy)

describe tidy do
  include PuppetSpec::Files

  before do
    @basepath = make_absolute("/what/ever")
    Puppet.settings.stubs(:use)
  end

  it "should use :lstat when stating a file" do
    path = '/foo/bar'
    resource = tidy.new :path => path, :age => "1d"
    stat = mock 'stat'
    stub_file = stub(path, :lstat => stat)
    Puppet::FileSystem::File.expects(:new).with(path).returns stub_file
    resource.stat(path).should == stat
  end

  [:age, :size, :path, :matches, :type, :recurse, :rmdirs].each do |param|
    it "should have a #{param} parameter" do
      Puppet::Type.type(:tidy).attrclass(param).ancestors.should be_include(Puppet::Parameter)
    end

    it "should have documentation for its #{param} param" do
      Puppet::Type.type(:tidy).attrclass(param).doc.should be_instance_of(String)
    end
  end

  describe "when validating parameter values" do
    describe "for 'recurse'" do
      before do
        @tidy = Puppet::Type.type(:tidy).new :path => "/tmp", :age => "100d"
      end

      it "should allow 'true'" do
        lambda { @tidy[:recurse] = true }.should_not raise_error
      end

      it "should allow 'false'" do
        lambda { @tidy[:recurse] = false }.should_not raise_error
      end

      it "should allow integers" do
        lambda { @tidy[:recurse] = 10 }.should_not raise_error
      end

      it "should allow string representations of integers" do
        lambda { @tidy[:recurse] = "10" }.should_not raise_error
      end

      it "should allow 'inf'" do
        lambda { @tidy[:recurse] = "inf" }.should_not raise_error
      end

      it "should not allow arbitrary values" do
        lambda { @tidy[:recurse] = "whatever" }.should raise_error
      end
    end

    describe "for 'matches'" do
      before do
        @tidy = Puppet::Type.type(:tidy).new :path => "/tmp", :age => "100d"
      end

      it "should object if matches is given with recurse is not specified" do
        lambda { @tidy[:matches] = '*.doh' }.should raise_error
      end
      it "should object if matches is given and recurse is 0" do
        lambda { @tidy[:recurse] = 0; @tidy[:matches] = '*.doh' }.should raise_error
      end
      it "should object if matches is given and recurse is false" do
        lambda { @tidy[:recurse] = false; @tidy[:matches] = '*.doh' }.should raise_error
      end
      it "should not object if matches is given and recurse is > 0" do
        lambda { @tidy[:recurse] = 1; @tidy[:matches] = '*.doh' }.should_not raise_error
      end
      it "should not object if matches is given and recurse is true" do
        lambda { @tidy[:recurse] = true; @tidy[:matches] = '*.doh' }.should_not raise_error
      end
    end
  end

  describe "when matching files by age" do
    convertors = {
      :second => 1,
      :minute => 60
    }

    convertors[:hour] = convertors[:minute] * 60
    convertors[:day] = convertors[:hour] * 24
    convertors[:week] = convertors[:day] * 7

    convertors.each do |unit, multiple|
      it "should consider a #{unit} to be #{multiple} seconds" do
        @tidy = Puppet::Type.type(:tidy).new :path => @basepath, :age => "5#{unit.to_s[0..0]}"

        @tidy[:age].should == 5 * multiple
      end
    end
  end

  describe "when matching files by size" do
    convertors = {
      :b => 0,
      :kb => 1,
      :mb => 2,
      :gb => 3,
      :tb => 4
    }

    convertors.each do |unit, multiple|
      it "should consider a #{unit} to be 1024^#{multiple} bytes" do
        @tidy = Puppet::Type.type(:tidy).new :path => @basepath, :size => "5#{unit}"

        total = 5
        multiple.times { total *= 1024 }
        @tidy[:size].should == total
      end
    end
  end

  describe "when tidying" do
    before do
      @tidy = Puppet::Type.type(:tidy).new :path => @basepath
      @stat = stub 'stat', :ftype => "directory"
      @stub_file = stub(@basepath, :lstat => @stat)
      Puppet::FileSystem::File.stubs(:new).with(@basepath).returns @stub_file
    end

    describe "and generating files" do
      it "should set the backup on the file if backup is set on the tidy instance" do
        @tidy[:backup] = "whatever"
        Puppet::Type.type(:file).expects(:new).with { |args| args[:backup] == "whatever" }

        @tidy.mkfile(@basepath)
      end

      it "should set the file's path to the tidy's path" do
        Puppet::Type.type(:file).expects(:new).with { |args| args[:path] == @basepath }

        @tidy.mkfile(@basepath)
      end

      it "should configure the file for deletion" do
        Puppet::Type.type(:file).expects(:new).with { |args| args[:ensure] == :absent }

        @tidy.mkfile(@basepath)
      end

      it "should force deletion on the file" do
        Puppet::Type.type(:file).expects(:new).with { |args| args[:force] == true }

        @tidy.mkfile(@basepath)
      end

      it "should do nothing if the targeted file does not exist" do
        @stub_file.expects(:lstat).raises Errno::ENOENT

        @tidy.generate.should == []
      end
    end

    describe "and recursion is not used" do
      it "should generate a file resource if the file should be tidied" do
        @tidy.expects(:tidy?).with(@basepath).returns true
        file = Puppet::Type.type(:file).new(:path => @basepath+"/eh")
        @tidy.expects(:mkfile).with(@basepath).returns file

        @tidy.generate.should == [file]
      end

      it "should do nothing if the file should not be tidied" do
        @tidy.expects(:tidy?).with(@basepath).returns false
        @tidy.expects(:mkfile).never

        @tidy.generate.should == []
      end
    end

    describe "and recursion is used" do
      before do
        @tidy[:recurse] = true
        Puppet::FileServing::Fileset.any_instance.stubs(:stat).returns mock("stat")
        @fileset = Puppet::FileServing::Fileset.new(@basepath)
        Puppet::FileServing::Fileset.stubs(:new).returns @fileset
      end

      it "should use a Fileset for infinite recursion" do
        Puppet::FileServing::Fileset.expects(:new).with(@basepath, :recurse => true).returns @fileset
        @fileset.expects(:files).returns %w{. one two}
        @tidy.stubs(:tidy?).returns false

        @tidy.generate
      end

      it "should use a Fileset for limited recursion" do
        @tidy[:recurse] = 42
        Puppet::FileServing::Fileset.expects(:new).with(@basepath, :recurse => true, :recurselimit => 42).returns @fileset
        @fileset.expects(:files).returns %w{. one two}
        @tidy.stubs(:tidy?).returns false

        @tidy.generate
      end

      it "should generate a file resource for every file that should be tidied but not for files that should not be tidied" do
        @fileset.expects(:files).returns %w{. one two}

        @tidy.expects(:tidy?).with(@basepath).returns true
        @tidy.expects(:tidy?).with(@basepath+"/one").returns true
        @tidy.expects(:tidy?).with(@basepath+"/two").returns false

        file = Puppet::Type.type(:file).new(:path => @basepath+"/eh")
        @tidy.expects(:mkfile).with(@basepath).returns file
        @tidy.expects(:mkfile).with(@basepath+"/one").returns file

        @tidy.generate
      end
    end

    describe "and determining whether a file matches provided glob patterns" do
      before do
        @tidy = Puppet::Type.type(:tidy).new :path => @basepath, :recurse => 1
        @tidy[:matches] = %w{*foo* *bar*}

        @stat = mock 'stat'

        @matcher = @tidy.parameter(:matches)
      end

      it "should always convert the globs to an array" do
        @matcher.value = "*foo*"
        @matcher.value.should == %w{*foo*}
      end

      it "should return true if any pattern matches the last part of the file" do
        @matcher.value = %w{*foo* *bar*}
        @matcher.must be_tidy("/file/yaybarness", @stat)
      end

      it "should return false if no pattern matches the last part of the file" do
        @matcher.value = %w{*foo* *bar*}
        @matcher.should_not be_tidy("/file/yayness", @stat)
      end
    end

    describe "and determining whether a file is too old" do
      before do
        @tidy = Puppet::Type.type(:tidy).new :path => @basepath
        @stat = stub 'stat'

        @tidy[:age] = "1s"
        @tidy[:type] = "mtime"
        @ager = @tidy.parameter(:age)
      end

      it "should use the age type specified" do
        @tidy[:type] = :ctime
        @stat.expects(:ctime).returns(Time.now)

        @ager.tidy?(@basepath, @stat)
      end

      it "should return false if the file is more recent than the specified age" do
        @stat.expects(:mtime).returns(Time.now)

        @ager.should_not be_tidy(@basepath, @stat)
      end

      it "should return true if the file is older than the specified age" do
        @stat.expects(:mtime).returns(Time.now - 10)

        @ager.must be_tidy(@basepath, @stat)
      end
    end

    describe "and determining whether a file is too large" do
      before do
        @tidy = Puppet::Type.type(:tidy).new :path => @basepath
        @stat = stub 'stat', :ftype => "file"

        @tidy[:size] = "1kb"
        @sizer = @tidy.parameter(:size)
      end

      it "should return false if the file is smaller than the specified size" do
        @stat.expects(:size).returns(4) # smaller than a kilobyte

        @sizer.should_not be_tidy(@basepath, @stat)
      end

      it "should return true if the file is larger than the specified size" do
        @stat.expects(:size).returns(1500) # larger than a kilobyte

        @sizer.must be_tidy(@basepath, @stat)
      end

      it "should return true if the file is equal to the specified size" do
        @stat.expects(:size).returns(1024)

        @sizer.must be_tidy(@basepath, @stat)
      end
    end

    describe "and determining whether a file should be tidied" do
      before do
        @tidy = Puppet::Type.type(:tidy).new :path => @basepath
        @stat = stub 'stat', :ftype => "file"
        @stub_file = stub(@basepath, :lstat => @stat)
        Puppet::FileSystem::File.expects(:new).with(@basepath).returns @stub_file
      end

      it "should not try to recurse if the file does not exist" do
        @tidy[:recurse] = true

        @stub_file.stubs(:lstat).returns nil

        @tidy.generate.should == []
      end

      it "should not be tidied if the file does not exist" do
        @stub_file.expects(:lstat).raises Errno::ENOENT

        @tidy.should_not be_tidy(@basepath)
      end

      it "should not be tidied if the user has no access to the file" do
        @stub_file.expects(:lstat).raises Errno::EACCES

        @tidy.should_not be_tidy(@basepath)
      end

      it "should not be tidied if it is a directory and rmdirs is set to false" do
        stat = mock 'stat', :ftype => "directory"
        @stub_file.expects(:lstat).returns stat

        @tidy.should_not be_tidy(@basepath)
      end

      it "should return false if it does not match any provided globs" do
        @tidy[:recurse] = 1
        @tidy[:matches] = "globs"

        matches = @tidy.parameter(:matches)
        matches.expects(:tidy?).with(@basepath, @stat).returns false
        @tidy.should_not be_tidy(@basepath)
      end

      it "should return false if it does not match aging requirements" do
        @tidy[:age] = "1d"

        ager = @tidy.parameter(:age)
        ager.expects(:tidy?).with(@basepath, @stat).returns false
        @tidy.should_not be_tidy(@basepath)
      end

      it "should return false if it does not match size requirements" do
        @tidy[:size] = "1b"

        sizer = @tidy.parameter(:size)
        sizer.expects(:tidy?).with(@basepath, @stat).returns false
        @tidy.should_not be_tidy(@basepath)
      end

      it "should tidy a file if age and size are set but only size matches" do
        @tidy[:size] = "1b"
        @tidy[:age] = "1d"

        @tidy.parameter(:size).stubs(:tidy?).returns true
        @tidy.parameter(:age).stubs(:tidy?).returns false
        @tidy.must be_tidy(@basepath)
      end

      it "should tidy a file if age and size are set but only age matches" do
        @tidy[:size] = "1b"
        @tidy[:age] = "1d"

        @tidy.parameter(:size).stubs(:tidy?).returns false
        @tidy.parameter(:age).stubs(:tidy?).returns true
        @tidy.must be_tidy(@basepath)
      end

      it "should tidy all files if neither age nor size is set" do
        @tidy.must be_tidy(@basepath)
      end

      it "should sort the results inversely by path length, so files are added to the catalog before their directories" do
        @tidy[:recurse] = true
        @tidy[:rmdirs] = true
        fileset = Puppet::FileServing::Fileset.new(@basepath)
        Puppet::FileServing::Fileset.expects(:new).returns fileset
        fileset.expects(:files).returns %w{. one one/two}

        @tidy.stubs(:tidy?).returns true

        @tidy.generate.collect { |r| r[:path] }.should == [@basepath+"/one/two", @basepath+"/one", @basepath]
      end
    end

    it "should configure directories to require their contained files if rmdirs is enabled, so the files will be deleted first" do
      @tidy[:recurse] = true
      @tidy[:rmdirs] = true
      fileset = mock 'fileset'
      Puppet::FileServing::Fileset.expects(:new).with(@basepath, :recurse => true).returns fileset
      fileset.expects(:files).returns %w{. one two one/subone two/subtwo one/subone/ssone}
      @tidy.stubs(:tidy?).returns true

      result = @tidy.generate.inject({}) { |hash, res| hash[res[:path]] = res; hash }
      {
        @basepath => [ @basepath+"/one", @basepath+"/two" ],
        @basepath+"/one" => [@basepath+"/one/subone"],
        @basepath+"/two" => [@basepath+"/two/subtwo"],
        @basepath+"/one/subone" => [@basepath+"/one/subone/ssone"]
      }.each do |parent, children|
        children.each do |child|
          ref = Puppet::Resource.new(:file, child)
          result[parent][:require].find { |req| req.to_s == ref.to_s }.should_not be_nil
        end
      end
    end
  end
end
