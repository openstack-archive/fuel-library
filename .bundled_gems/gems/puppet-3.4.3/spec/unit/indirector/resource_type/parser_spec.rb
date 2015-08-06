#! /usr/bin/env ruby
require 'spec_helper'

require 'puppet/indirector/resource_type/parser'
require 'puppet_spec/files'

describe Puppet::Indirector::ResourceType::Parser do
  include PuppetSpec::Files

  before do
    @terminus = Puppet::Indirector::ResourceType::Parser.new
    @request = Puppet::Indirector::Request.new(:resource_type, :find, "foo", nil)
    @krt = @request.environment.known_resource_types
  end

  it "should be registered with the resource_type indirection" do
    Puppet::Indirector::Terminus.terminus_class(:resource_type, :parser).should equal(Puppet::Indirector::ResourceType::Parser)
  end

  describe "when finding" do
    it "should return any found type from the request's environment" do
      type = Puppet::Resource::Type.new(:hostclass, "foo")
      @request.environment.known_resource_types.add(type)

      @terminus.find(@request).should == type
    end

    it "should attempt to load the type if none is found in memory" do
      dir = tmpdir("find_a_type")
      FileUtils.mkdir_p(dir)
      Puppet[:modulepath] = dir

      # Make a new request, since we've reset the env
      @request = Puppet::Indirector::Request.new(:resource_type, :find, "foo::bar", nil)

      manifest_path = File.join(dir, "foo", "manifests")
      FileUtils.mkdir_p(manifest_path)

      File.open(File.join(manifest_path, "bar.pp"), "w") { |f| f.puts "class foo::bar {}" }

      result = @terminus.find(@request)
      result.should be_instance_of(Puppet::Resource::Type)
      result.name.should == "foo::bar"
    end

    it "should return nil if no type can be found" do
      @terminus.find(@request).should be_nil
    end

    it "should prefer definitions to nodes" do
      type = @krt.add(Puppet::Resource::Type.new(:hostclass, "foo"))
      node = @krt.add(Puppet::Resource::Type.new(:node, "foo"))

      @terminus.find(@request).should == type
    end
  end

  describe "when searching" do
    describe "when the search key is a wildcard" do
      before do
        @request.key = "*"
      end

      it "should use the request's environment's list of known resource types" do
        @request.environment.known_resource_types.expects(:hostclasses).returns({})

        @terminus.search(@request)
      end

      it "should return all results if '*' is provided as the search string" do
        type = @krt.add(Puppet::Resource::Type.new(:hostclass, "foo"))
        node = @krt.add(Puppet::Resource::Type.new(:node, "bar"))
        define = @krt.add(Puppet::Resource::Type.new(:definition, "baz"))

        result = @terminus.search(@request)
        result.should be_include(type)
        result.should be_include(node)
        result.should be_include(define)
      end

      it "should return all known types" do
        type = @krt.add(Puppet::Resource::Type.new(:hostclass, "foo"))
        node = @krt.add(Puppet::Resource::Type.new(:node, "bar"))
        define = @krt.add(Puppet::Resource::Type.new(:definition, "baz"))

        result = @terminus.search(@request)
        result.should be_include(type)
        result.should be_include(node)
        result.should be_include(define)
      end

      it "should not return the 'main' class" do
        main = @krt.add(Puppet::Resource::Type.new(:hostclass, ""))

        # So there is a return value
        foo = @krt.add(Puppet::Resource::Type.new(:hostclass, "foo"))

        @terminus.search(@request).should_not be_include(main)
      end

      it "should return nil if no types can be found" do
        @terminus.search(@request).should be_nil
      end

      it "should load all resource types from all search paths" do
        dir = tmpdir("searching_in_all")
        first = File.join(dir, "first")
        second = File.join(dir, "second")
        FileUtils.mkdir_p(first)
        FileUtils.mkdir_p(second)
        Puppet[:modulepath] = "#{first}#{File::PATH_SEPARATOR}#{second}"

        # Make a new request, since we've reset the env
        @request = Puppet::Indirector::Request.new(:resource_type, :search, "*", nil)

        onepath = File.join(first, "one", "manifests")
        FileUtils.mkdir_p(onepath)
        twopath = File.join(first, "two", "manifests")
        FileUtils.mkdir_p(twopath)

        File.open(File.join(onepath, "oneklass.pp"), "w") { |f| f.puts "class one::oneklass {}" }
        File.open(File.join(twopath, "twoklass.pp"), "w") { |f| f.puts "class two::twoklass {}" }

        result = @terminus.search(@request)
        result.find { |t| t.name == "one::oneklass" }.should be_instance_of(Puppet::Resource::Type)
        result.find { |t| t.name == "two::twoklass" }.should be_instance_of(Puppet::Resource::Type)
      end

      context "when specifying a 'kind' parameter" do
        before :each do
          @klass = @krt.add(Puppet::Resource::Type.new(:hostclass, "foo"))
          @node = @krt.add(Puppet::Resource::Type.new(:node, "bar"))
          @define = @krt.add(Puppet::Resource::Type.new(:definition, "baz"))
        end

        it "should raise an error if you pass an invalid kind filter" do
          @request.options[:kind] = "i bet you don't have a kind called this"
          expect {
            @terminus.search(@request)
          }.to raise_error(ArgumentError, /Unrecognized kind filter/)

        end

        it "should support filtering for only hostclass results" do
          @request.options[:kind] = "class"

          result = @terminus.search(@request)
          result.should be_include(@klass)
          result.should_not be_include(@node)
          result.should_not be_include(@define)
        end

        it "should support filtering for only node results" do
          @request.options[:kind] = "node"

          result = @terminus.search(@request)
          result.should_not be_include(@klass)
          result.should be_include(@node)
          result.should_not be_include(@define)
        end

        it "should support filtering for only definition results" do
          @request.options[:kind] = "defined_type"

          result = @terminus.search(@request)
          result.should_not be_include(@klass)
          result.should_not be_include(@node)
          result.should be_include(@define)
        end
      end
    end

    context "when the search string is not a wildcard" do

      it "should treat any search string as a regex" do
        @request.key = "a"
        foo = @krt.add(Puppet::Resource::Type.new(:hostclass, "foo"))
        bar = @krt.add(Puppet::Resource::Type.new(:hostclass, "bar"))
        baz = @krt.add(Puppet::Resource::Type.new(:hostclass, "baz"))

        result = @terminus.search(@request)
        result.should be_include(bar)
        result.should be_include(baz)
        result.should_not be_include(foo)
      end

      it "should support kind filtering with a regex" do
        @request.key = "foo"
        @request.options[:kind] = "class"

        foobar = @krt.add(Puppet::Resource::Type.new(:hostclass, "foobar"))
        foobaz = @krt.add(Puppet::Resource::Type.new(:hostclass, "foobaz"))
        foobam = @krt.add(Puppet::Resource::Type.new(:definition, "foobam"))
        fooball = @krt.add(Puppet::Resource::Type.new(:node, "fooball"))

        result = @terminus.search(@request)
        result.should be_include(foobar)
        result.should be_include(foobaz)
        result.should_not be_include(foobam)
        result.should_not be_include(fooball)
      end

      it "should fail if a provided search string is not a valid regex" do
        @request.key = "*foo*"

        # Add one instance so we don't just get an empty array"
        @krt.add(Puppet::Resource::Type.new(:hostclass, "foo"))
        lambda { @terminus.search(@request) }.should raise_error(ArgumentError)
      end
    end

    it "should not return the 'main' class" do
      main = @krt.add(Puppet::Resource::Type.new(:hostclass, ""))

      # So there is a return value
      foo = @krt.add(Puppet::Resource::Type.new(:hostclass, "foo"))

      @terminus.search(@request).should_not be_include(main)
    end

    it "should return nil if no types can be found" do
      @terminus.search(@request).should be_nil
    end

    it "should load all resource types from all search paths" do
      dir = tmpdir("searching_in_all")
      first = File.join(dir, "first")
      second = File.join(dir, "second")
      FileUtils.mkdir_p(first)
      FileUtils.mkdir_p(second)
      Puppet[:modulepath] = "#{first}#{File::PATH_SEPARATOR}#{second}"

      # Make a new request, since we've reset the env
      @request = Puppet::Indirector::Request.new(:resource_type, :search, "*", nil)

      onepath = File.join(first, "one", "manifests")
      FileUtils.mkdir_p(onepath)
      twopath = File.join(first, "two", "manifests")
      FileUtils.mkdir_p(twopath)

      File.open(File.join(onepath, "oneklass.pp"), "w") { |f| f.puts "class one::oneklass {}" }
      File.open(File.join(twopath, "twoklass.pp"), "w") { |f| f.puts "class two::twoklass {}" }

      result = @terminus.search(@request)
      result.find { |t| t.name == "one::oneklass" }.should be_instance_of(Puppet::Resource::Type)
      result.find { |t| t.name == "two::twoklass" }.should be_instance_of(Puppet::Resource::Type)
    end
  end
end
