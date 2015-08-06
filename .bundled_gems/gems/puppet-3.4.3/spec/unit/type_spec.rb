#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet_spec/compiler'

describe Puppet::Type, :unless => Puppet.features.microsoft_windows? do
  include PuppetSpec::Files
  include PuppetSpec::Compiler

  it "should be Comparable" do
    a = Puppet::Type.type(:notify).new(:name => "a")
    b = Puppet::Type.type(:notify).new(:name => "b")
    c = Puppet::Type.type(:notify).new(:name => "c")

    [[a, b, c], [a, c, b], [b, a, c], [b, c, a], [c, a, b], [c, b, a]].each do |this|
      this.sort.should == [a, b, c]
    end

    a.must be < b
    a.must be < c
    b.must be > a
    b.must be < c
    c.must be > a
    c.must be > b

    [a, b, c].each {|x| a.must be <= x }
    [a, b, c].each {|x| c.must be >= x }

    b.must be_between(a, c)
  end

  it "should consider a parameter to be valid if it is a valid parameter" do
    Puppet::Type.type(:mount).should be_valid_parameter(:name)
  end

  it "should consider a parameter to be valid if it is a valid property" do
    Puppet::Type.type(:mount).should be_valid_parameter(:fstype)
  end

  it "should consider a parameter to be valid if it is a valid metaparam" do
    Puppet::Type.type(:mount).should be_valid_parameter(:noop)
  end

  it "should be able to retrieve a property by name" do
    resource = Puppet::Type.type(:mount).new(:name => "foo", :fstype => "bar", :pass => 1, :ensure => :present)
    resource.property(:fstype).must be_instance_of(Puppet::Type.type(:mount).attrclass(:fstype))
  end

  it "should be able to retrieve a parameter by name" do
    resource = Puppet::Type.type(:mount).new(:name => "foo", :fstype => "bar", :pass => 1, :ensure => :present)
    resource.parameter(:name).must be_instance_of(Puppet::Type.type(:mount).attrclass(:name))
  end

  it "should be able to retrieve a property by name using the :parameter method" do
    resource = Puppet::Type.type(:mount).new(:name => "foo", :fstype => "bar", :pass => 1, :ensure => :present)
    resource.parameter(:fstype).must be_instance_of(Puppet::Type.type(:mount).attrclass(:fstype))
  end

  it "should be able to retrieve all set properties" do
    resource = Puppet::Type.type(:mount).new(:name => "foo", :fstype => "bar", :pass => 1, :ensure => :present)
    props = resource.properties
    props.should_not be_include(nil)
    [:fstype, :ensure, :pass].each do |name|
      props.should be_include(resource.parameter(name))
    end
  end

  it "can retrieve all set parameters" do
    resource = Puppet::Type.type(:mount).new(:name => "foo", :fstype => "bar", :pass => 1, :ensure => :present, :tag => 'foo')
    params = resource.parameters_with_value
    [:name, :provider, :ensure, :fstype, :pass, :dump, :target, :loglevel, :tag].each do |name|
      params.should be_include(resource.parameter(name))
    end
  end

  it "can not return any `nil` values when retrieving all set parameters" do
    resource = Puppet::Type.type(:mount).new(:name => "foo", :fstype => "bar", :pass => 1, :ensure => :present, :tag => 'foo')
    params = resource.parameters_with_value
    params.should_not be_include(nil)
  end

  it "can return an iterator for all set parameters" do
    resource = Puppet::Type.type(:notify).new(:name=>'foo',:message=>'bar',:tag=>'baz',:require=> "File['foo']")
    params = [:name, :message, :withpath, :loglevel, :tag, :require]
    resource.eachparameter { |param|
      params.should be_include(param.to_s.to_sym)
    }
  end

  it "should have a method for setting default values for resources" do
    Puppet::Type.type(:mount).new(:name => "foo").must respond_to(:set_default)
  end

  it "should do nothing for attributes that have no defaults and no specified value" do
    Puppet::Type.type(:mount).new(:name => "foo").parameter(:noop).should be_nil
  end

  it "should have a method for adding tags" do
    Puppet::Type.type(:mount).new(:name => "foo").must respond_to(:tags)
  end

  it "should use the tagging module" do
    Puppet::Type.type(:mount).ancestors.should be_include(Puppet::Util::Tagging)
  end

  it "should delegate to the tagging module when tags are added" do
    resource = Puppet::Type.type(:mount).new(:name => "foo")
    resource.stubs(:tag).with(:mount)

    resource.expects(:tag).with(:tag1, :tag2)

    resource.tags = [:tag1,:tag2]
  end

  it "should add the current type as tag" do
    resource = Puppet::Type.type(:mount).new(:name => "foo")
    resource.stubs(:tag)

    resource.expects(:tag).with(:mount)

    resource.tags = [:tag1,:tag2]
  end

  it "should have a method to know if the resource is exported" do
    Puppet::Type.type(:mount).new(:name => "foo").must respond_to(:exported?)
  end

  it "should have a method to know if the resource is virtual" do
    Puppet::Type.type(:mount).new(:name => "foo").must respond_to(:virtual?)
  end

  it "should consider its version to be zero if it has no catalog" do
    Puppet::Type.type(:mount).new(:name => "foo").version.should == 0
  end

  it "reports the correct path even after path is used during setup of the type" do
    Puppet::Type.newtype(:testing) do
      newparam(:name) do
        isnamevar
        validate do |value|
          path # forces the computation of the path
        end
      end
    end

    ral = compile_to_ral(<<-MANIFEST)
      class something {
        testing { something: }
      }
      include something
    MANIFEST

    ral.resource("Testing[something]").path.should == "/Stage[main]/Something/Testing[something]"
  end

  context "alias metaparam" do
    it "creates a new name that can be used for resource references" do
      ral = compile_to_ral(<<-MANIFEST)
        notify { a: alias => c }
      MANIFEST

      expect(ral.resource("Notify[a]")).to eq(ral.resource("Notify[c]"))
    end
  end

  context "resource attributes" do
    let(:resource) {
      resource = Puppet::Type.type(:mount).new(:name => "foo")
      catalog = Puppet::Resource::Catalog.new
      catalog.version = 50
      catalog.add_resource resource
      resource
    }

    it "should consider its version to be its catalog version" do
      resource.version.should == 50
    end

    it "should have tags" do
      expect(resource).to be_tagged("mount")
      expect(resource).to be_tagged("foo")
    end

    it "should have a path" do
      resource.path.should == "/Mount[foo]"
    end
  end

  it "should consider its type to be the name of its class" do
    Puppet::Type.type(:mount).new(:name => "foo").type.should == :mount
  end

  it "should use any provided noop value" do
    Puppet::Type.type(:mount).new(:name => "foo", :noop => true).must be_noop
  end

  it "should use the global noop value if none is provided" do
    Puppet[:noop] = true
    Puppet::Type.type(:mount).new(:name => "foo").must be_noop
  end

  it "should not be noop if in a non-host_config catalog" do
    resource = Puppet::Type.type(:mount).new(:name => "foo")
    catalog = Puppet::Resource::Catalog.new
    catalog.add_resource resource
    resource.should_not be_noop
  end

  describe "when creating an event" do
    before do
      @resource = Puppet::Type.type(:mount).new :name => "foo"
    end

    it "should have the resource's reference as the resource" do
      @resource.event.resource.should == "Mount[foo]"
    end

    it "should have the resource's log level as the default log level" do
      @resource[:loglevel] = :warning
      @resource.event.default_log_level.should == :warning
    end

    {:file => "/my/file", :line => 50}.each do |attr, value|
      it "should set the #{attr}" do
        @resource.stubs(attr).returns value
        @resource.event.send(attr).should == value
      end
    end

    it "should set the tags" do
      @resource.tag("abc", "def")
      @resource.event.should be_tagged("abc")
      @resource.event.should be_tagged("def")
    end

    it "should allow specification of event attributes" do
      @resource.event(:status => "noop").status.should == "noop"
    end
  end

  describe "when creating a provider" do
    before :each do
      @type = Puppet::Type.newtype(:provider_test_type) do
        newparam(:name) { isnamevar }
        newparam(:foo)
        newproperty(:bar)
      end
    end

    after :each do
      @type.provider_hash.clear
    end

    describe "when determining if instances of the type are managed" do
      it "should not consider audit only resources to be managed" do
        @type.new(:name => "foo", :audit => 'all').managed?.should be_false
      end

      it "should not consider resources with only parameters to be managed" do
        @type.new(:name => "foo", :foo => 'did someone say food?').managed?.should be_false
      end

      it "should consider resources with any properties set to be managed" do
        @type.new(:name => "foo", :bar => 'Let us all go there').managed?.should be_true
      end
    end

    it "should have documentation for the 'provider' parameter if there are providers" do
      @type.provide(:test_provider)
      @type.paramdoc(:provider).should =~ /`provider_test_type`[\s\r]+resource/
    end

    it "should not have documentation for the 'provider' parameter if there are no providers" do
      expect { @type.paramdoc(:provider) }.to raise_error(NoMethodError)
    end

    it "should create a subclass of Puppet::Provider for the provider" do
      provider = @type.provide(:test_provider)

      provider.ancestors.should include(Puppet::Provider)
    end

    it "should use a parent class if specified" do
      parent_provider = @type.provide(:parent_provider)
      child_provider  = @type.provide(:child_provider, :parent => parent_provider)

      child_provider.ancestors.should include(parent_provider)
    end

    it "should use a parent class if specified by name" do
      parent_provider = @type.provide(:parent_provider)
      child_provider  = @type.provide(:child_provider, :parent => :parent_provider)

      child_provider.ancestors.should include(parent_provider)
    end

    it "should raise an error when the parent class can't be found" do
      expect {
        @type.provide(:child_provider, :parent => :parent_provider)
      }.to raise_error(Puppet::DevError, /Could not find parent provider.+parent_provider/)
    end

    it "should ensure its type has a 'provider' parameter" do
      @type.provide(:test_provider)

      @type.parameters.should include(:provider)
    end

    it "should remove a previously registered provider with the same name" do
      old_provider = @type.provide(:test_provider)
      new_provider = @type.provide(:test_provider)

      old_provider.should_not equal(new_provider)
    end

    it "should register itself as a provider for the type" do
      provider = @type.provide(:test_provider)

      provider.should == @type.provider(:test_provider)
    end

    it "should create a provider when a provider with the same name previously failed" do
      @type.provide(:test_provider) do
        raise "failed to create this provider"
      end rescue nil

      provider = @type.provide(:test_provider)

      provider.ancestors.should include(Puppet::Provider)
      provider.should == @type.provider(:test_provider)
    end
  end

  describe "when choosing a default provider" do
    it "should choose the provider with the highest specificity" do
      # Make a fake type
      type = Puppet::Type.newtype(:defaultprovidertest) do
        newparam(:name) do end
      end

      basic = type.provide(:basic) {}
      greater = type.provide(:greater) {}

      basic.stubs(:specificity).returns 1
      greater.stubs(:specificity).returns 2

      type.defaultprovider.should equal(greater)
    end
  end

  describe "when initializing" do
    describe "and passed a Puppet::Resource instance" do
      it "should set its title to the title of the resource if the resource type is equal to the current type" do
        resource = Puppet::Resource.new(:mount, "/foo", :parameters => {:name => "/other"})
        Puppet::Type.type(:mount).new(resource).title.should == "/foo"
      end

      it "should set its title to the resource reference if the resource type is not equal to the current type" do
        resource = Puppet::Resource.new(:user, "foo")
        Puppet::Type.type(:mount).new(resource).title.should == "User[foo]"
      end

      [:line, :file, :catalog, :exported, :virtual].each do |param|
        it "should copy '#{param}' from the resource if present" do
          resource = Puppet::Resource.new(:mount, "/foo")
          resource.send(param.to_s + "=", "foo")
          resource.send(param.to_s + "=", "foo")
          Puppet::Type.type(:mount).new(resource).send(param).should == "foo"
        end
      end

      it "should copy any tags from the resource" do
        resource = Puppet::Resource.new(:mount, "/foo")
        resource.tag "one", "two"
        tags = Puppet::Type.type(:mount).new(resource).tags
        tags.should be_include("one")
        tags.should be_include("two")
      end

      it "should copy the resource's parameters as its own" do
        resource = Puppet::Resource.new(:mount, "/foo", :parameters => {:atboot => :yes, :fstype => "boo"})
        params = Puppet::Type.type(:mount).new(resource).to_hash
        params[:fstype].should == "boo"
        params[:atboot].should == :yes
      end
    end

    describe "and passed a Hash" do
      it "should extract the title from the hash" do
        Puppet::Type.type(:mount).new(:title => "/yay").title.should == "/yay"
      end

      it "should work when hash keys are provided as strings" do
        Puppet::Type.type(:mount).new("title" => "/yay").title.should == "/yay"
      end

      it "should work when hash keys are provided as symbols" do
        Puppet::Type.type(:mount).new(:title => "/yay").title.should == "/yay"
      end

      it "should use the name from the hash as the title if no explicit title is provided" do
        Puppet::Type.type(:mount).new(:name => "/yay").title.should == "/yay"
      end

      it "should use the Resource Type's namevar to determine how to find the name in the hash" do
        yay = make_absolute('/yay')
        Puppet::Type.type(:file).new(:path => yay).title.should == yay
      end

      [:catalog].each do |param|
        it "should extract '#{param}' from the hash if present" do
          Puppet::Type.type(:mount).new(:name => "/yay", param => "foo").send(param).should == "foo"
        end
      end

      it "should use any remaining hash keys as its parameters" do
        resource = Puppet::Type.type(:mount).new(:title => "/foo", :catalog => "foo", :atboot => :yes, :fstype => "boo")
        resource[:fstype].must == "boo"
        resource[:atboot].must == :yes
      end
    end

    it "should fail if any invalid attributes have been provided" do
      expect { Puppet::Type.type(:mount).new(:title => "/foo", :nosuchattr => "whatever") }.to raise_error(Puppet::Error, /Invalid parameter/)
    end

    context "when an attribute fails validation" do
      it "should fail with Puppet::ResourceError when PuppetError raised" do
        expect { Puppet::Type.type(:file).new(:title => "/foo", :source => "unknown:///") }.to raise_error(Puppet::ResourceError, /Parameter source failed on File\[.*foo\]/)
      end

      it "should fail with Puppet::ResourceError when ArgumentError raised" do
        expect { Puppet::Type.type(:file).new(:title => "/foo", :mode => "abcdef") }.to raise_error(Puppet::ResourceError, /Parameter mode failed on File\[.*foo\]/)
      end

      it "should include the file/line in the error" do
        Puppet::Type.type(:file).any_instance.stubs(:file).returns("example.pp")
        Puppet::Type.type(:file).any_instance.stubs(:line).returns(42)
        expect { Puppet::Type.type(:file).new(:title => "/foo", :source => "unknown:///") }.to raise_error(Puppet::ResourceError, /example.pp:42/)
      end
    end

    it "should set its name to the resource's title if the resource does not have a :name or namevar parameter set" do
      resource = Puppet::Resource.new(:mount, "/foo")

      Puppet::Type.type(:mount).new(resource).name.should == "/foo"
    end

    it "should fail if no title, name, or namevar are provided" do
      expect { Puppet::Type.type(:mount).new(:atboot => :yes) }.to raise_error(Puppet::Error)
    end

    it "should set the attributes in the order returned by the class's :allattrs method" do
      Puppet::Type.type(:mount).stubs(:allattrs).returns([:name, :atboot, :noop])
      resource = Puppet::Resource.new(:mount, "/foo", :parameters => {:name => "myname", :atboot => :yes, :noop => "whatever"})

      set = []

      Puppet::Type.type(:mount).any_instance.stubs(:newattr).with do |param, hash|
        set << param
        true
      end.returns(stub_everything("a property"))

      Puppet::Type.type(:mount).new(resource)

      set[-1].should == :noop
      set[-2].should == :atboot
    end

    it "should always set the name and then default provider before anything else" do
      Puppet::Type.type(:mount).stubs(:allattrs).returns([:provider, :name, :atboot])
      resource = Puppet::Resource.new(:mount, "/foo", :parameters => {:name => "myname", :atboot => :yes})

      set = []

      Puppet::Type.type(:mount).any_instance.stubs(:newattr).with do |param, hash|
        set << param
        true
      end.returns(stub_everything("a property"))

      Puppet::Type.type(:mount).new(resource)
      set[0].should == :name
      set[1].should == :provider
    end

    # This one is really hard to test :/
    it "should set each default immediately if no value is provided" do
      defaults = []
      Puppet::Type.type(:service).any_instance.stubs(:set_default).with { |value| defaults << value; true }

      Puppet::Type.type(:service).new :name => "whatever"

      defaults[0].should == :provider
    end

    it "should retain a copy of the originally provided parameters" do
      Puppet::Type.type(:mount).new(:name => "foo", :atboot => :yes, :noop => false).original_parameters.should == {:atboot => :yes, :noop => false}
    end

    it "should delete the name via the namevar from the originally provided parameters" do
      Puppet::Type.type(:file).new(:name => make_absolute('/foo')).original_parameters[:path].should be_nil
    end

    context "when validating the resource" do
      it "should call the type's validate method if present" do
        Puppet::Type.type(:file).any_instance.expects(:validate)
        Puppet::Type.type(:file).new(:name => make_absolute('/foo'))
      end

      it "should raise Puppet::ResourceError with resource name when Puppet::Error raised" do
        expect do
          Puppet::Type.type(:file).new(
            :name => make_absolute('/foo'),
            :source => "puppet:///",
            :content => "foo"
          )
        end.to raise_error(Puppet::ResourceError, /Validation of File\[.*foo.*\]/)
      end

      it "should raise Puppet::ResourceError with manifest file and line on failure" do
        Puppet::Type.type(:file).any_instance.stubs(:file).returns("example.pp")
        Puppet::Type.type(:file).any_instance.stubs(:line).returns(42)
        expect do
          Puppet::Type.type(:file).new(
            :name => make_absolute('/foo'),
            :source => "puppet:///",
            :content => "foo"
          )
        end.to raise_error(Puppet::ResourceError, /Validation.*example.pp:42/)
      end
    end
  end

  describe "when #finish is called on a type" do
    let(:post_hook_type) do
      Puppet::Type.newtype(:finish_test) do
        newparam(:name) { isnamevar }

        newparam(:post) do
          def post_compile
            raise "post_compile hook ran"
          end
        end
      end
    end

    let(:post_hook_resource) do
      post_hook_type.new(:name => 'foo',:post => 'fake_value')
    end

    it "should call #post_compile on parameters that implement it" do
      expect { post_hook_resource.finish }.to raise_error(RuntimeError, "post_compile hook ran")
    end
  end

  it "should have a class method for converting a hash into a Puppet::Resource instance" do
    Puppet::Type.type(:mount).must respond_to(:hash2resource)
  end

  describe "when converting a hash to a Puppet::Resource instance" do
    before do
      @type = Puppet::Type.type(:mount)
    end

    it "should treat a :title key as the title of the resource" do
      @type.hash2resource(:name => "/foo", :title => "foo").title.should == "foo"
    end

    it "should use the name from the hash as the title if no explicit title is provided" do
      @type.hash2resource(:name => "foo").title.should == "foo"
    end

    it "should use the Resource Type's namevar to determine how to find the name in the hash" do
      @type.stubs(:key_attributes).returns([ :myname ])

      @type.hash2resource(:myname => "foo").title.should == "foo"
    end

    [:catalog].each do |attr|
      it "should use any provided #{attr}" do
        @type.hash2resource(:name => "foo", attr => "eh").send(attr).should == "eh"
      end
    end

    it "should set all provided parameters on the resource" do
      @type.hash2resource(:name => "foo", :fstype => "boo", :boot => "fee").to_hash.should == {:name => "foo", :fstype => "boo", :boot => "fee"}
    end

    it "should not set the title as a parameter on the resource" do
      @type.hash2resource(:name => "foo", :title => "eh")[:title].should be_nil
    end

    it "should not set the catalog as a parameter on the resource" do
      @type.hash2resource(:name => "foo", :catalog => "eh")[:catalog].should be_nil
    end

    it "should treat hash keys equivalently whether provided as strings or symbols" do
      resource = @type.hash2resource("name" => "foo", "title" => "eh", "fstype" => "boo")
      resource.title.should == "eh"
      resource[:name].should == "foo"
      resource[:fstype].should == "boo"
    end
  end

  describe "when retrieving current property values" do
    before do
      @resource = Puppet::Type.type(:mount).new(:name => "foo", :fstype => "bar", :pass => 1, :ensure => :present)
      @resource.property(:ensure).stubs(:retrieve).returns :absent
    end

    it "should fail if its provider is unsuitable" do
      @resource = Puppet::Type.type(:mount).new(:name => "foo", :fstype => "bar", :pass => 1, :ensure => :present)
      @resource.provider.class.expects(:suitable?).returns false
      expect { @resource.retrieve_resource }.to raise_error(Puppet::Error)
    end

    it "should return a Puppet::Resource instance with its type and title set appropriately" do
      result = @resource.retrieve_resource
      result.should be_instance_of(Puppet::Resource)
      result.type.should == "Mount"
      result.title.should == "foo"
    end

    it "should set the name of the returned resource if its own name and title differ" do
      @resource[:name] = "myname"
      @resource.title = "other name"
      @resource.retrieve_resource[:name].should == "myname"
    end

    it "should provide a value for all set properties" do
      values = @resource.retrieve_resource
      [:ensure, :fstype, :pass].each { |property| values[property].should_not be_nil }
    end

    it "should provide a value for 'ensure' even if no desired value is provided" do
      @resource = Puppet::Type.type(:file).new(:path => make_absolute("/my/file/that/can't/exist"))
    end

    it "should not call retrieve on non-ensure properties if the resource is absent and should consider the property absent" do
      @resource.property(:ensure).expects(:retrieve).returns :absent
      @resource.property(:fstype).expects(:retrieve).never
      @resource.retrieve_resource[:fstype].should == :absent
    end

    it "should include the result of retrieving each property's current value if the resource is present" do
      @resource.property(:ensure).expects(:retrieve).returns :present
      @resource.property(:fstype).expects(:retrieve).returns 15
      @resource.retrieve_resource[:fstype] == 15
    end
  end

  describe "#to_resource" do
    it "should return a Puppet::Resource that includes properties, parameters and tags" do
      type_resource = Puppet::Type.type(:mount).new(
        :ensure   => :present,
        :name     => "foo",
        :fstype   => "bar",
        :remounts => true
      )
      type_resource.tags = %w{bar baz}

      # If it's not a property it's a parameter
      type_resource.parameters[:remounts].should_not be_a(Puppet::Property)
      type_resource.parameters[:fstype].is_a?(Puppet::Property).should be_true

      type_resource.property(:ensure).expects(:retrieve).returns :present
      type_resource.property(:fstype).expects(:retrieve).returns 15

      resource = type_resource.to_resource

      resource.should be_a Puppet::Resource
      resource[:fstype].should   == 15
      resource[:remounts].should == :true
      resource.tags.should == Puppet::Util::TagSet.new(%w{foo bar baz mount})
    end
  end

  describe ".title_patterns" do
    describe "when there's one namevar" do
      before do
        @type_class = Puppet::Type.type(:notify)
        @type_class.stubs(:key_attributes).returns([:one])
      end

      it "should have a default pattern for when there's one namevar" do
        patterns = @type_class.title_patterns
        patterns.length.should == 1
        patterns[0].length.should == 2
      end

      it "should have a regexp that captures the entire string" do
        patterns = @type_class.title_patterns
        string = "abc\n\tdef"
        patterns[0][0] =~ string
        $1.should == "abc\n\tdef"
      end
    end
  end

  describe "when in a catalog" do
    before do
      @catalog = Puppet::Resource::Catalog.new
      @container = Puppet::Type.type(:component).new(:name => "container")
      @one = Puppet::Type.type(:file).new(:path => make_absolute("/file/one"))
      @two = Puppet::Type.type(:file).new(:path => make_absolute("/file/two"))

      @catalog.add_resource @container
      @catalog.add_resource @one
      @catalog.add_resource @two
      @catalog.add_edge @container, @one
      @catalog.add_edge @container, @two
    end

    it "should have no parent if there is no in edge" do
      @container.parent.should be_nil
    end

    it "should set its parent to its in edge" do
      @one.parent.ref.should == @container.ref
    end

    after do
      @catalog.clear(true)
    end
  end

  it "should have a 'stage' metaparam" do
    Puppet::Type.metaparamclass(:stage).should be_instance_of(Class)
  end

  describe "#suitable?" do
    let(:type) { Puppet::Type.type(:file) }
    let(:resource) { type.new :path => tmpfile('suitable') }
    let(:provider) { resource.provider }

    it "should be suitable if its type doesn't use providers" do
      type.stubs(:paramclass).with(:provider).returns nil
      resource.must be_suitable
    end

    it "should be suitable if it has a provider which is suitable" do
      resource.must be_suitable
    end

    it "should not be suitable if it has a provider which is not suitable" do
      provider.class.stubs(:suitable?).returns false
      resource.should_not be_suitable
    end

    it "should be suitable if it does not have a provider and there is a default provider" do
      resource.stubs(:provider).returns nil
      resource.must be_suitable
    end

    it "should not be suitable if it doesn't have a provider and there is not default provider" do
      resource.stubs(:provider).returns nil
      type.stubs(:defaultprovider).returns nil

      resource.should_not be_suitable
    end
  end

  describe "::instances" do
    after :each do Puppet::Type.rmtype(:type_spec_fake_type) end
    let :type do
      Puppet::Type.newtype(:type_spec_fake_type) do
        newparam(:name) do
          isnamevar
        end

        newproperty(:prop1) {}
      end

      Puppet::Type.type(:type_spec_fake_type)
    end

    it "should not fail if no suitable providers are found" do
      type.provide(:fake1) do
        confine :exists => '/no/such/file'
        mk_resource_methods
      end

      expect { type.instances.should == [] }.to_not raise_error
    end

    context "with a default provider" do
      before :each do
        type.provide(:default) do
          defaultfor :operatingsystem => Facter.value(:operatingsystem)
          mk_resource_methods
          class << self
            attr_accessor :names
          end
          def self.instance(name)
            new(:name => name, :ensure => :present)
          end
          def self.instances
            @instances ||= names.collect { |name| instance(name.to_s) }
          end

          @names = [:one, :two]
        end
      end

      it "should return only instances of the type" do
        type.instances.should be_all {|x| x.is_a? type }
      end

      it "should return instances from the default provider" do
        type.instances.map(&:name).should == ["one", "two"]
      end

      it "should return instances from all providers" do
        type.provide(:fake1, :parent => :default) { @names = [:three, :four] }
        type.instances.map(&:name).should == ["one", "two", "three", "four"]
      end

      it "should not return instances from unsuitable providers" do
        type.provide(:fake1, :parent => :default) do
          @names = [:three, :four]
          confine :exists => "/no/such/file"
        end

        type.instances.map(&:name).should == ["one", "two"]
      end
    end
  end


  describe "::ensurable?" do
    before :each do
      class TestEnsurableType < Puppet::Type
        def exists?; end
        def create; end
        def destroy; end
      end
    end

    it "is true if the class has exists?, create, and destroy methods defined" do
      TestEnsurableType.should be_ensurable
    end

    it "is false if exists? is not defined" do
      TestEnsurableType.class_eval { remove_method(:exists?) }
      TestEnsurableType.should_not be_ensurable
    end

    it "is false if create is not defined" do
      TestEnsurableType.class_eval { remove_method(:create) }
      TestEnsurableType.should_not be_ensurable
    end

    it "is false if destroy is not defined" do
      TestEnsurableType.class_eval { remove_method(:destroy) }
      TestEnsurableType.should_not be_ensurable
    end
  end
end

describe Puppet::Type::RelationshipMetaparam do
  include PuppetSpec::Files

  it "should be a subclass of Puppet::Parameter" do
    Puppet::Type::RelationshipMetaparam.superclass.should equal(Puppet::Parameter)
  end

  it "should be able to produce a list of subclasses" do
    Puppet::Type::RelationshipMetaparam.should respond_to(:subclasses)
  end

  describe "when munging relationships" do
    before do
      @path = File.expand_path('/foo')
      @resource = Puppet::Type.type(:file).new :name => @path
      @metaparam = Puppet::Type.metaparamclass(:require).new :resource => @resource
    end

    it "should accept Puppet::Resource instances" do
      ref = Puppet::Resource.new(:file, @path)
      @metaparam.munge(ref)[0].should equal(ref)
    end

    it "should turn any string into a Puppet::Resource" do
      @metaparam.munge("File[/ref]")[0].should be_instance_of(Puppet::Resource)
    end
  end

  it "should be able to validate relationships" do
    Puppet::Type.metaparamclass(:require).new(:resource => mock("resource")).should respond_to(:validate_relationship)
  end

  describe 'if any specified resource is not in the catalog' do
    let(:catalog) { mock 'catalog' }

    let(:resource) do
      stub 'resource',
        :catalog => catalog,
        :ref     => 'resource',
        :line=   => nil,
        :file=   => nil
    end

    let(:param) { Puppet::Type.metaparamclass(:require).new(:resource => resource, :value => %w{Foo[bar] Class[test]}) }

    before do
      catalog.expects(:resource).with("Foo[bar]").returns "something"
      catalog.expects(:resource).with("Class[Test]").returns nil
    end

    describe "and the resource doesn't have a file or line number" do
      it "raises an error" do
        expect { param.validate_relationship }.to raise_error do |error|
          error.should be_a Puppet::ResourceError
          error.message.should match %r[Class\[Test\]]
        end
      end
    end

    describe "and the resource has a file or line number" do
      before do
        resource.stubs(:line).returns '42'
        resource.stubs(:file).returns '/hitchhikers/guide/to/the/galaxy'
      end

      it "raises an error with context" do
        expect { param.validate_relationship }.to raise_error do |error|
          error.should be_a Puppet::ResourceError
          error.message.should match %r[Class\[Test\]]
          error.message.should match %r["in /hitchhikers/guide/to/the/galaxy:42"]
        end
      end
    end
  end
end

describe Puppet::Type.metaparamclass(:audit) do
  include PuppetSpec::Files

  before do
    @resource = Puppet::Type.type(:file).new :path => make_absolute('/foo')
  end

  it "should default to being nil" do
    @resource[:audit].should be_nil
  end

  it "should specify all possible properties when asked to audit all properties" do
    @resource[:audit] = :all

    list = @resource.class.properties.collect { |p| p.name }
    @resource[:audit].should == list
  end

  it "should accept the string 'all' to specify auditing all possible properties" do
    @resource[:audit] = 'all'

    list = @resource.class.properties.collect { |p| p.name }
    @resource[:audit].should == list
  end

  it "should fail if asked to audit an invalid property" do
    expect { @resource[:audit] = :foobar }.to raise_error(Puppet::Error)
  end

  it "should create an attribute instance for each auditable property" do
    @resource[:audit] = :mode
    @resource.parameter(:mode).should_not be_nil
  end

  it "should accept properties specified as a string" do
    @resource[:audit] = "mode"
    @resource.parameter(:mode).should_not be_nil
  end

  it "should not create attribute instances for parameters, only properties" do
    @resource[:audit] = :noop
    @resource.parameter(:noop).should be_nil
  end

  describe "when generating the uniqueness key" do
    it "should include all of the key_attributes in alphabetical order by attribute name" do
      Puppet::Type.type(:file).stubs(:key_attributes).returns [:path, :mode, :owner]
      Puppet::Type.type(:file).stubs(:title_patterns).returns(
        [ [ /(.*)/, [ [:path, lambda{|x| x} ] ] ] ]
      )
      myfile = make_absolute('/my/file')
      res = Puppet::Type.type(:file).new( :title => myfile, :path => myfile, :owner => 'root', :content => 'hello' )
      res.uniqueness_key.should == [ nil, 'root', myfile]
    end
  end

  context "type attribute bracket methods" do
    after :each do Puppet::Type.rmtype(:attributes)     end
    let   :type do
      Puppet::Type.newtype(:attributes) do
        newparam(:name) {}
      end
    end

    it "should work with parameters" do
      type.newparam(:param) {}
      instance = type.new(:name => 'test')

      expect { instance[:param] = true }.to_not raise_error
      expect { instance["param"] = true }.to_not raise_error
      instance[:param].should == true
      instance["param"].should == true
    end

    it "should work with meta-parameters" do
      instance = type.new(:name => 'test')

      expect { instance[:noop] = true }.to_not raise_error
      expect { instance["noop"] = true }.to_not raise_error
      instance[:noop].should == true
      instance["noop"].should == true
    end

    it "should work with properties" do
      type.newproperty(:property) {}
      instance = type.new(:name => 'test')

      expect { instance[:property] = true }.to_not raise_error
      expect { instance["property"] = true }.to_not raise_error
      instance.property(:property).must be
      instance.should(:property).must be_true
    end

    it "should handle proprieties correctly" do
      # Order of assignment is significant in this test.
      props = {}
      [:one, :two, :three].each {|prop| type.newproperty(prop) {} }
      instance = type.new(:name => "test")

      instance[:one] = "boo"
      one = instance.property(:one)
      instance.properties.must == [one]

      instance[:three] = "rah"
      three = instance.property(:three)
      instance.properties.must == [one, three]

      instance[:two] = "whee"
      two = instance.property(:two)
      instance.properties.must == [one, two, three]
    end

    it "newattr should handle required features correctly" do
      Puppet::Util::Log.level = :debug

      type.feature :feature1, "one"
      type.feature :feature2, "two"

      none = type.newproperty(:none) {}
      one  = type.newproperty(:one, :required_features => :feature1) {}
      two  = type.newproperty(:two, :required_features => [:feature1, :feature2]) {}

      nope  = type.provide(:nope)  {}
      maybe = type.provide(:maybe) { has_features :feature1 }
      yep   = type.provide(:yep)   { has_features :feature1, :feature2 }

      [nope, maybe, yep].each_with_index do |provider, i|
        rsrc = type.new(:provider => provider.name, :name => "test#{i}",
                        :none => "a", :one => "b", :two => "c")

        rsrc.should(:none).must be

        if provider.declared_feature? :feature1
          rsrc.should(:one).must be
        else
          rsrc.should(:one).must_not be
          @logs.find {|l| l.message =~ /not managing attribute one/ }.should be
        end

        if provider.declared_feature? :feature2
          rsrc.should(:two).must be
        else
          rsrc.should(:two).must_not be
          @logs.find {|l| l.message =~ /not managing attribute two/ }.should be
        end
      end
    end
  end
end
