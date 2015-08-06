#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet_spec/compiler'

class CompilerTestResource
  attr_accessor :builtin, :virtual, :evaluated, :type, :title

  def initialize(type, title)
    @type = type
    @title = title
  end

  def [](attr)
    return nil if attr == :stage
    :main
  end

  def ref
    "#{type.to_s.capitalize}[#{title}]"
  end

  def evaluated?
    @evaluated
  end

  def builtin_type?
    @builtin
  end

  def virtual?
    @virtual
  end

  def class?
    false
  end

  def stage?
    false
  end

  def evaluate
  end

  def file
    "/fake/file/goes/here"
  end

  def line
    "42"
  end
end

describe Puppet::Parser::Compiler do
  include PuppetSpec::Files

  def resource(type, title)
    Puppet::Parser::Resource.new(type, title, :scope => @scope)
  end

  before :each do
    # Push me faster, I wanna go back in time!  (Specifically, freeze time
    # across the test since we have a bunch of version == timestamp code
    # hidden away in the implementation and we keep losing the race.)
    # --daniel 2011-04-21
    now = Time.now
    Time.stubs(:now).returns(now)

    @node = Puppet::Node.new("testnode", :facts => Puppet::Node::Facts.new("facts", {}))
    @known_resource_types = Puppet::Resource::TypeCollection.new "development"
    @compiler = Puppet::Parser::Compiler.new(@node)
    @scope = Puppet::Parser::Scope.new(@compiler, :source => stub('source'))
    @scope_resource = Puppet::Parser::Resource.new(:file, "/my/file", :scope => @scope)
    @scope.resource = @scope_resource
    @compiler.environment.stubs(:known_resource_types).returns @known_resource_types
  end

  it "should have a class method that compiles, converts, and returns a catalog" do
    compiler = stub 'compiler'
    Puppet::Parser::Compiler.expects(:new).with(@node).returns compiler
    catalog = stub 'catalog'
    compiler.expects(:compile).returns catalog
    converted_catalog = stub 'converted_catalog'
    catalog.expects(:to_resource).returns converted_catalog

    Puppet::Parser::Compiler.compile(@node).should equal(converted_catalog)
  end

  it "should fail intelligently when a class-level compile fails" do
    Puppet::Parser::Compiler.expects(:new).raises ArgumentError
    lambda { Puppet::Parser::Compiler.compile(@node) }.should raise_error(Puppet::Error)
  end

  it "should use the node's environment as its environment" do
    @compiler.environment.should equal(@node.environment)
  end

  it "should include the resource type collection helper" do
    Puppet::Parser::Compiler.ancestors.should be_include(Puppet::Resource::TypeCollectionHelper)
  end

  it "should be able to return a class list containing all added classes" do
    @compiler.add_class ""
    @compiler.add_class "one"
    @compiler.add_class "two"

    @compiler.classlist.sort.should == %w{one two}.sort
  end

  it "should clear the global caches before compile" do
    compiler = stub 'compiler'
    Puppet::Parser::Compiler.expects(:new).with(@node).returns compiler
    catalog = stub 'catalog'
    compiler.expects(:compile).returns catalog
    catalog.expects(:to_resource)

    $known_resource_types = "rspec"
    $env_module_directories = "rspec"

    Puppet::Parser::Compiler.compile(@node)

    $known_resource_types = nil
    $env_module_directories = nil
  end

  describe "when initializing" do

    it "should set its node attribute" do
      @compiler.node.should equal(@node)
    end
    it "should detect when ast nodes are absent" do
      @compiler.ast_nodes?.should be_false
    end

    it "should detect when ast nodes are present" do
      @known_resource_types.expects(:nodes?).returns true
      @compiler.ast_nodes?.should be_true
    end

    it "should copy the known_resource_types version to the catalog" do
      @compiler.catalog.version.should == @known_resource_types.version
    end

    it "should copy any node classes into the class list" do
      node = Puppet::Node.new("mynode")
      node.classes = %w{foo bar}
      compiler = Puppet::Parser::Compiler.new(node)

      compiler.classlist.should =~ ['foo', 'bar']
    end

    it "should transform node class hashes into a class list" do
      node = Puppet::Node.new("mynode")
      node.classes = {'foo'=>{'one'=>'p1'}, 'bar'=>{'two'=>'p2'}}
      compiler = Puppet::Parser::Compiler.new(node)

      compiler.classlist.should =~ ['foo', 'bar']
    end

    it "should add a 'main' stage to the catalog" do
      @compiler.catalog.resource(:stage, :main).should be_instance_of(Puppet::Parser::Resource)
    end
  end

  describe "when managing scopes" do

    it "should create a top scope" do
      @compiler.topscope.should be_instance_of(Puppet::Parser::Scope)
    end

    it "should be able to create new scopes" do
      @compiler.newscope(@compiler.topscope).should be_instance_of(Puppet::Parser::Scope)
    end

    it "should set the parent scope of the new scope to be the passed-in parent" do
      scope = mock 'scope'
      newscope = @compiler.newscope(scope)

      newscope.parent.should equal(scope)
    end

    it "should set the parent scope of the new scope to its topscope if the parent passed in is nil" do
      scope = mock 'scope'
      newscope = @compiler.newscope(nil)

      newscope.parent.should equal(@compiler.topscope)
    end
  end

  describe "when compiling" do

    def compile_methods
      [:set_node_parameters, :evaluate_main, :evaluate_ast_node, :evaluate_node_classes, :evaluate_generators, :fail_on_unevaluated,
        :finish, :store, :extract, :evaluate_relationships]
    end

    # Stub all of the main compile methods except the ones we're specifically interested in.
    def compile_stub(*except)
      (compile_methods - except).each { |m| @compiler.stubs(m) }
    end

    it "should set node parameters as variables in the top scope" do
      params = {"a" => "b", "c" => "d"}
      @node.stubs(:parameters).returns(params)
      compile_stub(:set_node_parameters)
      @compiler.compile
      @compiler.topscope['a'].should == "b"
      @compiler.topscope['c'].should == "d"
    end

    it "should set the client and server versions on the catalog" do
      params = {"clientversion" => "2", "serverversion" => "3"}
      @node.stubs(:parameters).returns(params)
      compile_stub(:set_node_parameters)
      @compiler.compile
      @compiler.catalog.client_version.should == "2"
      @compiler.catalog.server_version.should == "3"
    end

    it "should evaluate the main class if it exists" do
      compile_stub(:evaluate_main)
      main_class = @known_resource_types.add Puppet::Resource::Type.new(:hostclass, "")
      main_class.expects(:evaluate_code).with { |r| r.is_a?(Puppet::Parser::Resource) }
      @compiler.topscope.expects(:source=).with(main_class)

      @compiler.compile
    end

    it "should create a new, empty 'main' if no main class exists" do
      compile_stub(:evaluate_main)
      @compiler.compile
      @known_resource_types.find_hostclass([""], "").should be_instance_of(Puppet::Resource::Type)
    end

    it "should add an edge between the main stage and main class" do
      @compiler.compile
      (stage = @compiler.catalog.resource(:stage, "main")).should be_instance_of(Puppet::Parser::Resource)
      (klass = @compiler.catalog.resource(:class, "")).should be_instance_of(Puppet::Parser::Resource)

      @compiler.catalog.edge?(stage, klass).should be_true
    end

    it "should evaluate all added collections" do
      colls = []
      # And when the collections fail to evaluate.
      colls << mock("coll1-false")
      colls << mock("coll2-false")
      colls.each { |c| c.expects(:evaluate).returns(false) }

      @compiler.add_collection(colls[0])
      @compiler.add_collection(colls[1])

      compile_stub(:evaluate_generators)
      @compiler.compile
    end

    it "should ignore builtin resources" do
      resource = resource(:file, "testing")

      @compiler.add_resource(@scope, resource)
      resource.expects(:evaluate).never

      @compiler.compile
    end

    it "should evaluate unevaluated resources" do
      resource = CompilerTestResource.new(:file, "testing")

      @compiler.add_resource(@scope, resource)

      # We have to now mark the resource as evaluated
      resource.expects(:evaluate).with { |*whatever| resource.evaluated = true }

      @compiler.compile
    end

    it "should not evaluate already-evaluated resources" do
      resource = resource(:file, "testing")
      resource.stubs(:evaluated?).returns true

      @compiler.add_resource(@scope, resource)
      resource.expects(:evaluate).never

      @compiler.compile
    end

    it "should evaluate unevaluated resources created by evaluating other resources" do
      resource = CompilerTestResource.new(:file, "testing")
      @compiler.add_resource(@scope, resource)

      resource2 = CompilerTestResource.new(:file, "other")

      # We have to now mark the resource as evaluated
      resource.expects(:evaluate).with { |*whatever| resource.evaluated = true; @compiler.add_resource(@scope, resource2) }
      resource2.expects(:evaluate).with { |*whatever| resource2.evaluated = true }


      @compiler.compile
    end

    describe "when finishing" do
      before do
        @compiler.send(:evaluate_main)
        @catalog = @compiler.catalog
      end

      def add_resource(name, parent = nil)
        resource = Puppet::Parser::Resource.new "file", name, :scope => @scope
        @compiler.add_resource(@scope, resource)
        @catalog.add_edge(parent, resource) if parent
        resource
      end

      it "should call finish() on all resources" do
        # Add a resource that does respond to :finish
        resource = Puppet::Parser::Resource.new "file", "finish", :scope => @scope
        resource.expects(:finish)

        @compiler.add_resource(@scope, resource)

        # And one that does not
        dnf_resource = stub_everything "dnf", :ref => "File[dnf]", :type => "file"

        @compiler.add_resource(@scope, dnf_resource)

        @compiler.send(:finish)
      end

      it "should call finish() in add_resource order" do
        resources = sequence('resources')

        resource1 = add_resource("finish1")
        resource1.expects(:finish).in_sequence(resources)

        resource2 = add_resource("finish2")
        resource2.expects(:finish).in_sequence(resources)

        @compiler.send(:finish)
      end

      it "should add each container's metaparams to its contained resources" do
        main = @catalog.resource(:class, :main)
        main[:noop] = true

        resource1 = add_resource("meh", main)

        @compiler.send(:finish)
        resource1[:noop].should be_true
      end

      it "should add metaparams recursively" do
        main = @catalog.resource(:class, :main)
        main[:noop] = true

        resource1 = add_resource("meh", main)
        resource2 = add_resource("foo", resource1)

        @compiler.send(:finish)
        resource2[:noop].should be_true
      end

      it "should prefer metaparams from immediate parents" do
        main = @catalog.resource(:class, :main)
        main[:noop] = true

        resource1 = add_resource("meh", main)
        resource2 = add_resource("foo", resource1)

        resource1[:noop] = false

        @compiler.send(:finish)
        resource2[:noop].should be_false
      end

      it "should merge tags downward" do
        main = @catalog.resource(:class, :main)
        main.tag("one")

        resource1 = add_resource("meh", main)
        resource1.tag "two"
        resource2 = add_resource("foo", resource1)

        @compiler.send(:finish)
        resource2.tags.should be_include("one")
        resource2.tags.should be_include("two")
      end

      it "should work if only middle resources have metaparams set" do
        main = @catalog.resource(:class, :main)

        resource1 = add_resource("meh", main)
        resource1[:noop] = true
        resource2 = add_resource("foo", resource1)

        @compiler.send(:finish)
        resource2[:noop].should be_true
      end
    end

    it "should return added resources in add order" do
      resource1 = resource(:file, "yay")
      @compiler.add_resource(@scope, resource1)
      resource2 = resource(:file, "youpi")
      @compiler.add_resource(@scope, resource2)

      @compiler.resources.should == [resource1, resource2]
    end

    it "should add resources that do not conflict with existing resources" do
      resource = resource(:file, "yay")
      @compiler.add_resource(@scope, resource)

      @compiler.catalog.should be_vertex(resource)
    end

    it "should fail to add resources that conflict with existing resources" do
      path = make_absolute("/foo")
      file1 = resource(:file, path)
      file2 = resource(:file, path)

      @compiler.add_resource(@scope, file1)
      lambda { @compiler.add_resource(@scope, file2) }.should raise_error(Puppet::Resource::Catalog::DuplicateResourceError)
    end

    it "should add an edge from the scope resource to the added resource" do
      resource = resource(:file, "yay")
      @compiler.add_resource(@scope, resource)

      @compiler.catalog.should be_edge(@scope.resource, resource)
    end

    it "should not add non-class resources that don't specify a stage to the 'main' stage" do
      main = @compiler.catalog.resource(:stage, :main)
      resource = resource(:file, "foo")
      @compiler.add_resource(@scope, resource)

      @compiler.catalog.should_not be_edge(main, resource)
    end

    it "should not add any parent-edges to stages" do
      stage = resource(:stage, "other")
      @compiler.add_resource(@scope, stage)

      @scope.resource = resource(:class, "foo")

      @compiler.catalog.edge?(@scope.resource, stage).should be_false
    end

    it "should not attempt to add stages to other stages" do
      other_stage = resource(:stage, "other")
      second_stage = resource(:stage, "second")
      @compiler.add_resource(@scope, other_stage)
      @compiler.add_resource(@scope, second_stage)

      second_stage[:stage] = "other"

      @compiler.catalog.edge?(other_stage, second_stage).should be_false
    end

    it "should have a method for looking up resources" do
      resource = resource(:yay, "foo")
      @compiler.add_resource(@scope, resource)
      @compiler.findresource("Yay[foo]").should equal(resource)
    end

    it "should be able to look resources up by type and title" do
      resource = resource(:yay, "foo")
      @compiler.add_resource(@scope, resource)
      @compiler.findresource("Yay", "foo").should equal(resource)
    end

    it "should not evaluate virtual defined resources" do
      resource = resource(:file, "testing")
      resource.virtual = true
      @compiler.add_resource(@scope, resource)

      resource.expects(:evaluate).never

      @compiler.compile
    end
  end

  describe "when evaluating collections" do

    it "should evaluate each collection" do
      2.times { |i|
        coll = mock 'coll%s' % i
        @compiler.add_collection(coll)

        # This is the hard part -- we have to emulate the fact that
        # collections delete themselves if they are done evaluating.
        coll.expects(:evaluate).with do
          @compiler.delete_collection(coll)
        end
      }

      @compiler.compile
    end

    it "should not fail when there are unevaluated resource collections that do not refer to specific resources" do
      coll = stub 'coll', :evaluate => false
      coll.expects(:resources).returns(nil)

      @compiler.add_collection(coll)

      lambda { @compiler.compile }.should_not raise_error
    end

    it "should fail when there are unevaluated resource collections that refer to a specific resource" do
      coll = stub 'coll', :evaluate => false
      coll.expects(:resources).returns(:something)

      @compiler.add_collection(coll)

      lambda { @compiler.compile }.should raise_error Puppet::ParseError, 'Failed to realize virtual resources something'
    end

    it "should fail when there are unevaluated resource collections that refer to multiple specific resources" do
      coll = stub 'coll', :evaluate => false
      coll.expects(:resources).returns([:one, :two])

      @compiler.add_collection(coll)

      lambda { @compiler.compile }.should raise_error Puppet::ParseError, 'Failed to realize virtual resources one, two'
    end
  end

  describe "when evaluating relationships" do
    it "should evaluate each relationship with its catalog" do
      dep = stub 'dep'
      dep.expects(:evaluate).with(@compiler.catalog)
      @compiler.add_relationship dep
      @compiler.evaluate_relationships
    end
  end

  describe "when told to evaluate missing classes" do

    it "should fail if there's no source listed for the scope" do
      scope = stub 'scope', :source => nil
      proc { @compiler.evaluate_classes(%w{one two}, scope) }.should raise_error(Puppet::DevError)
    end

    it "should raise an error if a class is not found" do
      @scope.expects(:find_hostclass).with("notfound", {:assume_fqname => false}).returns(nil)
      lambda{ @compiler.evaluate_classes(%w{notfound}, @scope) }.should raise_error(Puppet::Error, /Could not find class/)
    end

    it "should raise an error when it can't find class" do
      klasses = {'foo'=>nil}
      @node.classes = klasses
      @compiler.topscope.expects(:find_hostclass).with('foo', {:assume_fqname => false}).returns(nil)
      lambda{ @compiler.compile }.should raise_error(Puppet::Error, /Could not find class foo for testnode/)
    end
  end

  describe "when evaluating found classes" do

    before do
      Puppet.settings[:data_binding_terminus] = "none"
      @class = stub 'class', :name => "my::class"
      @scope.stubs(:find_hostclass).with("myclass", {:assume_fqname => false}).returns(@class)

      @resource = stub 'resource', :ref => "Class[myclass]", :type => "file"
    end

    it "should evaluate each class" do
      @compiler.catalog.stubs(:tag)

      @class.expects(:ensure_in_catalog).with(@scope)
      @scope.stubs(:class_scope).with(@class)

      @compiler.evaluate_classes(%w{myclass}, @scope)
    end

    describe "and the classes are specified as a hash with parameters" do
      before do
        @node.classes = {}
        @ast_obj = Puppet::Parser::AST::String.new(:value => 'foo')
      end

      # Define the given class with default parameters
      def define_class(name, parameters)
        @node.classes[name] = parameters
        klass = Puppet::Resource::Type.new(:hostclass, name, :arguments => {'p1' => @ast_obj, 'p2' => @ast_obj})
        @compiler.topscope.known_resource_types.add klass
      end

      def compile
        @catalog = @compiler.compile
      end

      it "should record which classes are evaluated" do
        classes = {'foo'=>{}, 'bar::foo'=>{}, 'bar'=>{}}
        classes.each { |c, params| define_class(c, params) }
        compile()
        classes.each { |name, p| @catalog.classes.should include(name) }
      end

      it "should provide default values for parameters that have no values specified" do
        define_class('foo', {})
        compile()
        @catalog.resource(:class, 'foo')['p1'].should == "foo"
      end

      it "should use any provided values" do
        define_class('foo', {'p1' => 'real_value'})
        compile()
        @catalog.resource(:class, 'foo')['p1'].should == "real_value"
      end

      it "should support providing some but not all values" do
        define_class('foo', {'p1' => 'real_value'})
        compile()
        @catalog.resource(:class, 'Foo')['p1'].should == "real_value"
        @catalog.resource(:class, 'Foo')['p2'].should == "foo"
      end

      it "should ensure each node class is in catalog and has appropriate tags" do
        klasses = ['bar::foo']
        @node.classes = klasses
        ast_obj = Puppet::Parser::AST::String.new(:value => 'foo')
        klasses.each do |name|
          klass = Puppet::Resource::Type.new(:hostclass, name, :arguments => {'p1' => ast_obj, 'p2' => ast_obj})
          @compiler.topscope.known_resource_types.add klass
        end
        catalog = @compiler.compile

        r2 = catalog.resources.detect {|r| r.title == 'Bar::Foo' }
        r2.tags.should == Puppet::Util::TagSet.new(['bar::foo', 'class', 'bar', 'foo'])
      end
    end

    it "should fail if required parameters are missing" do
      klass = {'foo'=>{'a'=>'one'}}
      @node.classes = klass
      klass = Puppet::Resource::Type.new(:hostclass, 'foo', :arguments => {'a' => nil, 'b' => nil})
      @compiler.topscope.known_resource_types.add klass
      lambda { @compiler.compile }.should raise_error(Puppet::ParseError, "Must pass b to Class[Foo]")
    end

    it "should fail if invalid parameters are passed" do
      klass = {'foo'=>{'3'=>'one'}}
      @node.classes = klass
      klass = Puppet::Resource::Type.new(:hostclass, 'foo', :arguments => {})
      @compiler.topscope.known_resource_types.add klass
      lambda { @compiler.compile }.should raise_error(Puppet::ParseError, "Invalid parameter 3")
    end

    it "should ensure class is in catalog without params" do
      @node.classes = klasses = {'foo'=>nil}
      foo = Puppet::Resource::Type.new(:hostclass, 'foo')
      @compiler.topscope.known_resource_types.add foo
      catalog = @compiler.compile
      catalog.classes.should include 'foo'
    end

    it "should not evaluate the resources created for found classes unless asked" do
      @compiler.catalog.stubs(:tag)

      @resource.expects(:evaluate).never

      @class.expects(:ensure_in_catalog).returns(@resource)
      @scope.stubs(:class_scope).with(@class)

      @compiler.evaluate_classes(%w{myclass}, @scope)
    end

    it "should immediately evaluate the resources created for found classes when asked" do
      @compiler.catalog.stubs(:tag)

      @resource.expects(:evaluate)
      @class.expects(:ensure_in_catalog).returns(@resource)
      @scope.stubs(:class_scope).with(@class)

      @compiler.evaluate_classes(%w{myclass}, @scope, false)
    end

    it "should skip classes that have already been evaluated" do
      @compiler.catalog.stubs(:tag)

      @scope.stubs(:class_scope).with(@class).returns("something")

      @compiler.expects(:add_resource).never

      @resource.expects(:evaluate).never

      Puppet::Parser::Resource.expects(:new).never
      @compiler.evaluate_classes(%w{myclass}, @scope, false)
    end

    it "should skip classes previously evaluated with different capitalization" do
      @compiler.catalog.stubs(:tag)
      @scope.stubs(:find_hostclass).with("MyClass",{:assume_fqname => false}).returns(@class)
      @scope.stubs(:class_scope).with(@class).returns("something")
      @compiler.expects(:add_resource).never
      @resource.expects(:evaluate).never
      Puppet::Parser::Resource.expects(:new).never
      @compiler.evaluate_classes(%w{MyClass}, @scope, false)
    end
  end

  describe "when evaluating AST nodes with no AST nodes present" do

    it "should do nothing" do
      @compiler.expects(:ast_nodes?).returns(false)
      @compiler.known_resource_types.expects(:nodes).never
      Puppet::Parser::Resource.expects(:new).never

      @compiler.send(:evaluate_ast_node)
    end
  end

  describe "when evaluating AST nodes with AST nodes present" do

    before do
      @compiler.known_resource_types.stubs(:nodes?).returns true

      # Set some names for our test
      @node.stubs(:names).returns(%w{a b c})
      @compiler.known_resource_types.stubs(:node).with("a").returns(nil)
      @compiler.known_resource_types.stubs(:node).with("b").returns(nil)
      @compiler.known_resource_types.stubs(:node).with("c").returns(nil)

      # It should check this last, of course.
      @compiler.known_resource_types.stubs(:node).with("default").returns(nil)
    end

    it "should fail if the named node cannot be found" do
      proc { @compiler.send(:evaluate_ast_node) }.should raise_error(Puppet::ParseError)
    end

    it "should evaluate the first node class matching the node name" do
      node_class = stub 'node', :name => "c", :evaluate_code => nil
      @compiler.known_resource_types.stubs(:node).with("c").returns(node_class)

      node_resource = stub 'node resource', :ref => "Node[c]", :evaluate => nil, :type => "node"
      node_class.expects(:ensure_in_catalog).returns(node_resource)

      @compiler.compile
    end

    it "should match the default node if no matching node can be found" do
      node_class = stub 'node', :name => "default", :evaluate_code => nil
      @compiler.known_resource_types.stubs(:node).with("default").returns(node_class)

      node_resource = stub 'node resource', :ref => "Node[default]", :evaluate => nil, :type => "node"
      node_class.expects(:ensure_in_catalog).returns(node_resource)

      @compiler.compile
    end

    it "should evaluate the node resource immediately rather than using lazy evaluation" do
      node_class = stub 'node', :name => "c"
      @compiler.known_resource_types.stubs(:node).with("c").returns(node_class)

      node_resource = stub 'node resource', :ref => "Node[c]", :type => "node"
      node_class.expects(:ensure_in_catalog).returns(node_resource)

      node_resource.expects(:evaluate)

      @compiler.send(:evaluate_ast_node)
    end
  end

  describe "when evaluating node classes" do
    include PuppetSpec::Compiler

    describe "when provided classes in array format" do
      let(:node) { Puppet::Node.new('someone', :classes => ['something']) }

      describe "when the class exists" do
        it "should succeed if the class is already included" do
          manifest = <<-MANIFEST
          class something {}
          include something
          MANIFEST

          catalog = compile_to_catalog(manifest, node)

          catalog.resource('Class', 'Something').should_not be_nil
        end

        it "should evaluate the class without parameters if it's not already included" do
          manifest = "class something {}"

          catalog = compile_to_catalog(manifest, node)

          catalog.resource('Class', 'Something').should_not be_nil
        end
      end

      it "should fail if the class doesn't exist" do
        expect { compile_to_catalog('', node) }.to raise_error(Puppet::Error, /Could not find class something/)
      end
    end

    describe "when provided classes in hash format" do
      describe "for classes without parameters" do
        let(:node) { Puppet::Node.new('someone', :classes => {'something' => {}}) }

        describe "when the class exists" do
          it "should succeed if the class is already included" do
            manifest = <<-MANIFEST
            class something {}
            include something
            MANIFEST

            catalog = compile_to_catalog(manifest, node)

            catalog.resource('Class', 'Something').should_not be_nil
          end

          it "should evaluate the class if it's not already included" do
            manifest = <<-MANIFEST
            class something {}
            MANIFEST

            catalog = compile_to_catalog(manifest, node)

            catalog.resource('Class', 'Something').should_not be_nil
          end
        end

        it "should fail if the class doesn't exist" do
          expect { compile_to_catalog('', node) }.to raise_error(Puppet::Error, /Could not find class something/)
        end
      end

      describe "for classes with parameters" do
        let(:node) { Puppet::Node.new('someone', :classes => {'something' => {'configuron' => 'defrabulated'}}) }

        describe "when the class exists" do
          it "should fail if the class is already included" do
            manifest = <<-MANIFEST
            class something($configuron=frabulated) {}
            include something
            MANIFEST

            expect { compile_to_catalog(manifest, node) }.to raise_error(Puppet::Error, /Class\[Something\] is already declared/)
          end

          it "should evaluate the class if it's not already included" do
            manifest = <<-MANIFEST
            class something($configuron=frabulated) {}
            MANIFEST

            catalog = compile_to_catalog(manifest, node)

            resource = catalog.resource('Class', 'Something')
            resource['configuron'].should == 'defrabulated'
          end
        end

        it "should fail if the class doesn't exist" do
          expect { compile_to_catalog('', node) }.to raise_error(Puppet::Error, /Could not find class something/)
        end
      end
    end
  end

  describe "when managing resource overrides" do

    before do
      @override = stub 'override', :ref => "File[/foo]", :type => "my"
      @resource = resource(:file, "/foo")
    end

    it "should be able to store overrides" do
      lambda { @compiler.add_override(@override) }.should_not raise_error
    end

    it "should apply overrides to the appropriate resources" do
      @compiler.add_resource(@scope, @resource)
      @resource.expects(:merge).with(@override)

      @compiler.add_override(@override)

      @compiler.compile
    end

    it "should accept overrides before the related resource has been created" do
      @resource.expects(:merge).with(@override)

      # First store the override
      @compiler.add_override(@override)

      # Then the resource
      @compiler.add_resource(@scope, @resource)

      # And compile, so they get resolved
      @compiler.compile
    end

    it "should fail if the compile is finished and resource overrides have not been applied" do
      @compiler.add_override(@override)

      lambda { @compiler.compile }.should raise_error Puppet::ParseError, 'Could not find resource(s) File[/foo] for overriding'
    end
  end
end
