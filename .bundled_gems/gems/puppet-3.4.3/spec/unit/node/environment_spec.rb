#! /usr/bin/env ruby
require 'spec_helper'

require 'tmpdir'

require 'puppet/node/environment'
require 'puppet/util/execution'
require 'puppet_spec/modules'
require 'puppet/parser/parser_factory'

describe Puppet::Node::Environment do
  let(:env) { Puppet::Node::Environment.new("testing") }

  include PuppetSpec::Files
  after do
    Puppet::Node::Environment.clear
  end

  shared_examples_for 'the environment' do
    it "should use the filetimeout for the ttl for the modulepath" do
      Puppet::Node::Environment.attr_ttl(:modulepath).should == Integer(Puppet[:filetimeout])
    end

    it "should use the filetimeout for the ttl for the module list" do
      Puppet::Node::Environment.attr_ttl(:modules).should == Integer(Puppet[:filetimeout])
    end

    it "should use the default environment if no name is provided while initializing an environment" do
      Puppet[:environment] = "one"
      Puppet::Node::Environment.new.name.should == :one
    end

    it "should treat environment instances as singletons" do
      Puppet::Node::Environment.new("one").should equal(Puppet::Node::Environment.new("one"))
    end

    it "should treat an environment specified as names or strings as equivalent" do
      Puppet::Node::Environment.new(:one).should equal(Puppet::Node::Environment.new("one"))
    end

    it "should return its name when converted to a string" do
      Puppet::Node::Environment.new(:one).to_s.should == "one"
    end

    it "should just return any provided environment if an environment is provided as the name" do
      one = Puppet::Node::Environment.new(:one)
      Puppet::Node::Environment.new(one).should equal(one)
    end

    describe "when managing known resource types" do
      before do
        @collection = Puppet::Resource::TypeCollection.new(env)
        env.stubs(:perform_initial_import).returns(Puppet::Parser::AST::Hostclass.new(''))
      end

      it "should create a resource type collection if none exists" do
        Puppet::Resource::TypeCollection.expects(:new).with(env).returns @collection
        env.known_resource_types.should equal(@collection)
      end

      it "should reuse any existing resource type collection" do
        env.known_resource_types.should equal(env.known_resource_types)
      end

      it "should perform the initial import when creating a new collection" do
        env.expects(:perform_initial_import).returns(Puppet::Parser::AST::Hostclass.new(''))
        env.known_resource_types
      end

      it "should return the same collection even if stale if it's the same thread" do
        Puppet::Resource::TypeCollection.stubs(:new).returns @collection
        env.known_resource_types.stubs(:stale?).returns true

        env.known_resource_types.should equal(@collection)
      end

      it "should generate a new TypeCollection if the current one requires reparsing" do
        old_type_collection = env.known_resource_types
        old_type_collection.stubs(:require_reparse?).returns true

        env.check_for_reparse

        new_type_collection = env.known_resource_types
        new_type_collection.should be_a Puppet::Resource::TypeCollection
        new_type_collection.should_not equal(old_type_collection)
      end
    end

    it "should validate the modulepath directories" do
      real_file = tmpdir('moduledir')
      path = %W[/one /two #{real_file}].join(File::PATH_SEPARATOR)

      Puppet[:modulepath] = path

      env.modulepath.should == [real_file]
    end

    it "should prefix the value of the 'PUPPETLIB' environment variable to the module path if present" do
      Puppet::Util.withenv("PUPPETLIB" => %w{/l1 /l2}.join(File::PATH_SEPARATOR)) do
        module_path = %w{/one /two}.join(File::PATH_SEPARATOR)
        env.expects(:validate_dirs).with(%w{/l1 /l2 /one /two}).returns %w{/l1 /l2 /one /two}
        env.expects(:[]).with(:modulepath).returns module_path

        env.modulepath.should == %w{/l1 /l2 /one /two}
      end
    end

    describe "when validating modulepath or manifestdir directories" do
      before :each do
        @path_one = tmpdir("path_one")
        @path_two = tmpdir("path_one")
        sep = File::PATH_SEPARATOR
        Puppet[:modulepath] = "#{@path_one}#{sep}#{@path_two}"
      end

      it "should not return non-directories" do
        FileTest.expects(:directory?).with(@path_one).returns true
        FileTest.expects(:directory?).with(@path_two).returns false

        env.validate_dirs([@path_one, @path_two]).should == [@path_one]
      end

      it "should use the current working directory to fully-qualify unqualified paths" do
        FileTest.stubs(:directory?).returns true
        two = File.expand_path("two")

        env.validate_dirs([@path_one, 'two']).should == [@path_one, two]
      end
    end

    describe "when modeling a specific environment" do
      it "should have a method for returning the environment name" do
        Puppet::Node::Environment.new("testing").name.should == :testing
      end

      it "should provide an array-like accessor method for returning any environment-specific setting" do
        env.should respond_to(:[])
      end

      it "should ask the Puppet settings instance for the setting qualified with the environment name" do
        Puppet.settings.set_value(:server, "myval", :testing)
        env[:server].should == "myval"
      end

      it "should be able to return an individual module that exists in its module path" do
        env.stubs(:modules).returns [Puppet::Module.new('one', "/one", mock("env"))]

        mod = env.module('one')
        mod.should be_a(Puppet::Module)
        mod.name.should == 'one'
      end

      it "should not return a module if the module doesn't exist" do
        env.stubs(:modules).returns [Puppet::Module.new('one', "/one", mock("env"))]

        env.module('two').should be_nil
      end

      it "should return nil if asked for a module that does not exist in its path" do
        modpath = tmpdir('modpath')
        env.modulepath = [modpath]

        env.module("one").should be_nil
      end

      describe "module data" do
        before do
          dir = tmpdir("deep_path")

          @first = File.join(dir, "first")
          @second = File.join(dir, "second")
          Puppet[:modulepath] = "#{@first}#{File::PATH_SEPARATOR}#{@second}"

          FileUtils.mkdir_p(@first)
          FileUtils.mkdir_p(@second)
        end

        describe "#modules_by_path" do
          it "should return an empty list if there are no modules" do
            env.modules_by_path.should == {
              @first  => [],
              @second => []
            }
          end

          it "should include modules even if they exist in multiple dirs in the modulepath" do
            modpath1 = File.join(@first, "foo")
            FileUtils.mkdir_p(modpath1)
            modpath2 = File.join(@second, "foo")
            FileUtils.mkdir_p(modpath2)

            env.modules_by_path.should == {
              @first  => [Puppet::Module.new('foo', modpath1, env)],
              @second => [Puppet::Module.new('foo', modpath2, env)]
            }
          end

          it "should ignore modules with invalid names" do
            FileUtils.mkdir_p(File.join(@first, 'foo'))
            FileUtils.mkdir_p(File.join(@first, 'foo2'))
            FileUtils.mkdir_p(File.join(@first, 'foo-bar'))
            FileUtils.mkdir_p(File.join(@first, 'foo_bar'))
            FileUtils.mkdir_p(File.join(@first, 'foo=bar'))
            FileUtils.mkdir_p(File.join(@first, 'foo bar'))
            FileUtils.mkdir_p(File.join(@first, 'foo.bar'))
            FileUtils.mkdir_p(File.join(@first, '-foo'))
            FileUtils.mkdir_p(File.join(@first, 'foo-'))
            FileUtils.mkdir_p(File.join(@first, 'foo--bar'))

            env.modules_by_path[@first].collect{|mod| mod.name}.sort.should == %w{foo foo-bar foo2 foo_bar}
          end

        end

        describe "#module_requirements" do
          it "should return a list of what modules depend on other modules" do
            PuppetSpec::Modules.create(
              'foo',
              @first,
              :metadata => {
                :author       => 'puppetlabs',
                :dependencies => [{ 'name' => 'puppetlabs/bar', "version_requirement" => ">= 1.0.0" }]
              }
            )
            PuppetSpec::Modules.create(
              'bar',
              @second,
              :metadata => {
                :author       => 'puppetlabs',
                :dependencies => [{ 'name' => 'puppetlabs/foo', "version_requirement" => "<= 2.0.0" }]
              }
            )
            PuppetSpec::Modules.create(
              'baz',
              @first,
              :metadata => {
                :author       => 'puppetlabs',
                :dependencies => [{ 'name' => 'puppetlabs/bar', "version_requirement" => "3.0.0" }]
              }
            )
            PuppetSpec::Modules.create(
              'alpha',
              @first,
              :metadata => {
                :author       => 'puppetlabs',
                :dependencies => [{ 'name' => 'puppetlabs/bar', "version_requirement" => "~3.0.0" }]
              }
            )

            env.module_requirements.should == {
              'puppetlabs/alpha' => [],
              'puppetlabs/foo' => [
                {
                  "name"    => "puppetlabs/bar",
                  "version" => "9.9.9",
                  "version_requirement" => "<= 2.0.0"
                }
              ],
              'puppetlabs/bar' => [
                {
                  "name"    => "puppetlabs/alpha",
                  "version" => "9.9.9",
                  "version_requirement" => "~3.0.0"
                },
                {
                  "name"    => "puppetlabs/baz",
                  "version" => "9.9.9",
                  "version_requirement" => "3.0.0"
                },
                {
                  "name"    => "puppetlabs/foo",
                  "version" => "9.9.9",
                  "version_requirement" => ">= 1.0.0"
                }
              ],
              'puppetlabs/baz' => []
            }
          end
        end

        describe ".module_by_forge_name" do
          it "should find modules by forge_name" do
            mod = PuppetSpec::Modules.create(
              'baz',
              @first,
              :metadata => {:author => 'puppetlabs'},
              :environment => env
            )
            env.module_by_forge_name('puppetlabs/baz').should == mod
          end

          it "should not find modules with same name by the wrong author" do
            mod = PuppetSpec::Modules.create(
              'baz',
              @first,
              :metadata => {:author => 'sneakylabs'},
              :environment => env
            )
            env.module_by_forge_name('puppetlabs/baz').should == nil
          end

          it "should return nil when the module can't be found" do
            env.module_by_forge_name('ima/nothere').should be_nil
          end
        end

        describe ".modules" do
          it "should return an empty list if there are no modules" do
            env.modules.should == []
          end

          it "should return a module named for every directory in each module path" do
            %w{foo bar}.each do |mod_name|
              FileUtils.mkdir_p(File.join(@first, mod_name))
            end
            %w{bee baz}.each do |mod_name|
              FileUtils.mkdir_p(File.join(@second, mod_name))
            end
            env.modules.collect{|mod| mod.name}.sort.should == %w{foo bar bee baz}.sort
          end

          it "should remove duplicates" do
            FileUtils.mkdir_p(File.join(@first,  'foo'))
            FileUtils.mkdir_p(File.join(@second, 'foo'))

            env.modules.collect{|mod| mod.name}.sort.should == %w{foo}
          end

          it "should ignore modules with invalid names" do
            FileUtils.mkdir_p(File.join(@first, 'foo'))
            FileUtils.mkdir_p(File.join(@first, 'foo2'))
            FileUtils.mkdir_p(File.join(@first, 'foo-bar'))
            FileUtils.mkdir_p(File.join(@first, 'foo_bar'))
            FileUtils.mkdir_p(File.join(@first, 'foo=bar'))
            FileUtils.mkdir_p(File.join(@first, 'foo bar'))

            env.modules.collect{|mod| mod.name}.sort.should == %w{foo foo-bar foo2 foo_bar}
          end

          it "should create modules with the correct environment" do
            FileUtils.mkdir_p(File.join(@first, 'foo'))
            env.modules.each {|mod| mod.environment.should == env }
          end

        end
      end

      it "should cache the module list" do
        env.modulepath = %w{/a}
        Dir.expects(:entries).once.with("/a").returns %w{foo}

        env.modules
        env.modules
      end
    end

    describe Puppet::Node::Environment::Helper do
      before do
        @helper = Object.new
        @helper.extend(Puppet::Node::Environment::Helper)
      end

      it "should be able to set and retrieve the environment as a symbol" do
        @helper.environment = :foo
        @helper.environment.name.should == :foo
      end

      it "should accept an environment directly" do
        @helper.environment = Puppet::Node::Environment.new(:foo)
        @helper.environment.name.should == :foo
      end

      it "should accept an environment as a string" do
        @helper.environment = 'foo'
        @helper.environment.name.should == :foo
      end
    end

    describe "when performing initial import" do
      before do
        @parser = Puppet::Parser::ParserFactory.parser("test")
#        @parser = Puppet::Parser::EParserAdapter.new(Puppet::Parser::Parser.new("test")) # TODO: FIX PARSER FACTORY
        Puppet::Parser::ParserFactory.stubs(:parser).returns @parser
      end

      it "should set the parser's string to the 'code' setting and parse if code is available" do
        Puppet.settings[:code] = "my code"
        @parser.expects(:string=).with "my code"
        @parser.expects(:parse)
        env.instance_eval { perform_initial_import }
      end

      it "should set the parser's file to the 'manifest' setting and parse if no code is available and the manifest is available" do
        filename = tmpfile('myfile')
        File.open(filename, 'w'){|f| }
        Puppet.settings[:manifest] = filename
        @parser.expects(:file=).with filename
        @parser.expects(:parse)
        env.instance_eval { perform_initial_import }
      end

      it "should pass the manifest file to the parser even if it does not exist on disk" do
        filename = tmpfile('myfile')
        Puppet.settings[:code] = ""
        Puppet.settings[:manifest] = filename
        @parser.expects(:file=).with(filename).once
        @parser.expects(:parse).once
        env.instance_eval { perform_initial_import }
      end

      it "should fail helpfully if there is an error importing" do
        Puppet::FileSystem::File.stubs(:exist?).returns true
        @parser.expects(:file=).once
        @parser.expects(:parse).raises ArgumentError
        lambda { env.known_resource_types }.should raise_error(Puppet::Error)
      end

      it "should not do anything if the ignore_import settings is set" do
        Puppet.settings[:ignoreimport] = true
        @parser.expects(:string=).never
        @parser.expects(:file=).never
        @parser.expects(:parse).never
        env.instance_eval { perform_initial_import }
      end

      it "should mark the type collection as needing a reparse when there is an error parsing" do
        @parser.expects(:parse).raises Puppet::ParseError.new("Syntax error at ...")

        lambda { env.known_resource_types }.should raise_error(Puppet::Error, /Syntax error at .../)
        env.known_resource_types.require_reparse?.should be_true
      end
    end
  end
  describe 'with classic parser' do
    before :each do
      Puppet[:parser] = 'current'
    end
    it_behaves_like 'the environment'
  end
  describe 'with future parser' do
    before :each do
      Puppet[:parser] = 'future'
    end
    it_behaves_like 'the environment'
  end

end
