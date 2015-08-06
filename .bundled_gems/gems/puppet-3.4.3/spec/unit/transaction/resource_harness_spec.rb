#! /usr/bin/env ruby
require 'spec_helper'

require 'puppet/transaction/resource_harness'

describe Puppet::Transaction::ResourceHarness do
  include PuppetSpec::Files

  before do
    @mode_750 = Puppet.features.microsoft_windows? ? '644' : '750'
    @mode_755 = Puppet.features.microsoft_windows? ? '644' : '755'
    path = make_absolute("/my/file")

    @transaction = Puppet::Transaction.new(Puppet::Resource::Catalog.new, nil, nil)
    @resource = Puppet::Type.type(:file).new :path => path
    @harness = Puppet::Transaction::ResourceHarness.new(@transaction)
    @current_state = Puppet::Resource.new(:file, path)
    @resource.stubs(:retrieve).returns @current_state
  end

  it "should accept a transaction at initialization" do
    harness = Puppet::Transaction::ResourceHarness.new(@transaction)
    harness.transaction.should equal(@transaction)
  end

  it "should delegate to the transaction for its relationship graph" do
    @transaction.expects(:relationship_graph).returns "relgraph"
    Puppet::Transaction::ResourceHarness.new(@transaction).relationship_graph.should == "relgraph"
  end

  describe "when evaluating a resource" do
    it "produces a resource state that describes what happened with the resource" do
      status = @harness.evaluate(@resource)

      status.resource.should == @resource.ref
      status.should_not be_failed
      status.events.should be_empty
    end

    it "retrieves the current state of the resource" do
      @resource.expects(:retrieve).returns @current_state

      @harness.evaluate(@resource)
    end

    it "produces a failure status for the resource when an error occurs" do
      the_message = "retrieve failed in testing"
      @resource.expects(:retrieve).raises(ArgumentError.new(the_message))

      status = @harness.evaluate(@resource)

      status.should be_failed
      events_to_hash(status.events).collect do |event|
        { :@status => event[:@status], :@message => event[:@message] }
      end.should == [{ :@status => "failure", :@message => the_message }]
    end

    it "records the time it took to evaluate the resource" do
      before = Time.now
      status = @harness.evaluate(@resource)
      after = Time.now

      status.evaluation_time.should be <= after - before
    end
  end

  def events_to_hash(events)
    events.map do |event|
      hash = {}
      event.instance_variables.each do |varname|
        hash[varname.to_sym] = event.instance_variable_get(varname)
      end
      hash
    end
  end

  def make_stub_provider
    stubProvider = Class.new(Puppet::Type)
    stubProvider.instance_eval do
      initvars

      newparam(:name) do
        desc "The name var"
        isnamevar
      end

      newproperty(:foo) do
        desc "A property that can be changed successfully"
        def sync
        end

        def retrieve
          :absent
        end

        def insync?(reference_value)
          false
        end
      end

      newproperty(:bar) do
        desc "A property that raises an exception when you try to change it"
        def sync
          raise ZeroDivisionError.new('bar')
        end

        def retrieve
          :absent
        end

        def insync?(reference_value)
          false
        end
      end

      newproperty(:baz) do
        desc "A property that raises an Exception (not StandardError) when you try to change it"
        def sync
          raise Exception.new('baz')
        end

        def retrieve
          :absent
        end

        def insync?(reference_value)
          false
        end
      end

      newproperty(:brillig) do
        desc "A property that raises a StandardError exception when you test if it's insync?"
        def sync
        end

        def retrieve
          :absent
        end

        def insync?(reference_value)
          raise ZeroDivisionError.new('brillig')
        end
      end

      newproperty(:slithy) do
        desc "A property that raises an Exception when you test if it's insync?"
        def sync
        end

        def retrieve
          :absent
        end

        def insync?(reference_value)
          raise Exception.new('slithy')
        end
      end
    end
    stubProvider
  end


  context "interaction of ensure with other properties" do
    def an_ensurable_resource_reacting_as(behaviors)
      stub_type = Class.new(Puppet::Type)
      stub_type.class_eval do
        initvars
        ensurable do
          def sync
            (@resource.behaviors[:on_ensure] || proc {}).call
          end

          def insync?(value)
            @resource.behaviors[:ensure_insync?]
          end
        end

        newparam(:name) do
          desc "The name var"
          isnamevar
        end

        newproperty(:prop) do
          newvalue("new") do
            #noop
          end

          def retrieve
            "old"
          end
        end

        attr_reader :behaviors

        def initialize(options)
          @behaviors = options.delete(:behaviors)
          super
        end

        def exists?
          @behaviors[:present?]
        end

        def present?(resource)
          @behaviors[:present?]
        end

        def self.name
          "Testing"
        end
      end
      stub_type.new(:behaviors => behaviors,
                    :ensure => :present,
                    :name => "testing",
                    :prop => "new")
    end

    it "ensure errors means that the rest doesn't happen" do
      resource = an_ensurable_resource_reacting_as(:ensure_insync? => false, :on_ensure => proc { raise StandardError }, :present? => true)

      status = @harness.evaluate(resource)

      expect(status.events.length).to eq(1)
      expect(status.events[0].property).to eq('ensure')
      expect(status.events[0].name.to_s).to eq('Testing_created')
      expect(status.events[0].status).to eq('failure')
    end

    it "ensure fails completely means that the rest doesn't happen" do
      resource = an_ensurable_resource_reacting_as(:ensure_insync? => false, :on_ensure => proc { raise Exception }, :present? => false)

      expect do
        @harness.evaluate(resource)
      end.to raise_error(Exception)

      @logs.first.message.should == "change from absent to present failed: Exception"
      @logs.first.level.should == :err
    end

    it "ensure succeeds means that the rest doesn't happen" do
      resource = an_ensurable_resource_reacting_as(:ensure_insync? => false, :on_ensure => proc { }, :present? => true)

      status = @harness.evaluate(resource)

      expect(status.events.length).to eq(1)
      expect(status.events[0].property).to eq('ensure')
      expect(status.events[0].name.to_s).to eq('Testing_created')
      expect(status.events[0].status).to eq('success')
    end

    it "ensure is in sync means that the rest *does* happen" do
      resource = an_ensurable_resource_reacting_as(:ensure_insync? => true, :present? => true)

      status = @harness.evaluate(resource)

      expect(status.events.length).to eq(1)
      expect(status.events[0].property).to eq('prop')
      expect(status.events[0].name.to_s).to eq('prop_changed')
      expect(status.events[0].status).to eq('success')
    end

    it "ensure is in sync but resource not present, means that the rest doesn't happen" do
      resource = an_ensurable_resource_reacting_as(:ensure_insync? => true, :present? => false)

      status = @harness.evaluate(resource)

      expect(status.events).to be_empty
    end
  end

  describe "when a caught error occurs" do
    before :each do
      stub_provider = make_stub_provider
      resource = stub_provider.new :name => 'name', :foo => 1, :bar => 2
      resource.expects(:err).never
      @status = @harness.evaluate(resource)
    end

    it "should record previous successful events" do
      @status.events[0].property.should == 'foo'
      @status.events[0].status.should == 'success'
    end

    it "should record a failure event" do
      @status.events[1].property.should == 'bar'
      @status.events[1].status.should == 'failure'
    end
  end

  describe "when an Exception occurs during sync" do
    before :each do
      stub_provider = make_stub_provider
      @resource = stub_provider.new :name => 'name', :baz => 1
      @resource.expects(:err).never
    end

    it "should log and pass the exception through" do
      lambda { @harness.evaluate(@resource) }.should raise_error(Exception, /baz/)
      @logs.first.message.should == "change from absent to 1 failed: baz"
      @logs.first.level.should == :err
    end
  end

  describe "when a StandardError exception occurs during insync?" do
    before :each do
      stub_provider = make_stub_provider
      @resource = stub_provider.new :name => 'name', :brillig => 1
      @resource.expects(:err).never
    end

    it "should record a failure event" do
      @status = @harness.evaluate(@resource)
      @status.events[0].name.to_s.should == 'brillig_changed'
      @status.events[0].property.should == 'brillig'
      @status.events[0].status.should == 'failure'
    end
  end

  describe "when an Exception occurs during insync?" do
    before :each do
      stub_provider = make_stub_provider
      @resource = stub_provider.new :name => 'name', :slithy => 1
      @resource.expects(:err).never
    end

    it "should log and pass the exception through" do
      lambda { @harness.evaluate(@resource) }.should raise_error(Exception, /slithy/)
      @logs.first.message.should == "change from absent to 1 failed: slithy"
      @logs.first.level.should == :err
    end
  end

  describe "when auditing" do
    it "should not call insync? on parameters that are merely audited" do
      stub_provider = make_stub_provider
      resource = stub_provider.new :name => 'name', :audit => ['foo']
      resource.property(:foo).expects(:insync?).never
      status = @harness.evaluate(resource)

      expect(status.events).to be_empty
    end

    it "should be able to audit a file's group" do # see bug #5710
      test_file = tmpfile('foo')
      File.open(test_file, 'w').close
      resource = Puppet::Type.type(:file).new :path => test_file, :audit => ['group'], :backup => false
      resource.expects(:err).never # make sure no exceptions get swallowed

      status = @harness.evaluate(resource)

      status.events.each do |event|
        event.status.should != 'failure'
      end
    end
  end

  describe "when applying changes" do
    it "should not apply changes if allow_changes?() returns false" do
      test_file = tmpfile('foo')
      resource = Puppet::Type.type(:file).new :path => test_file, :backup => false, :ensure => :file
      resource.expects(:err).never # make sure no exceptions get swallowed
      @harness.expects(:allow_changes?).with(resource).returns false
      status = @harness.evaluate(resource)
      Puppet::FileSystem::File.exist?(test_file).should == false
    end
  end

  describe "when determining whether the resource can be changed" do
    before do
      @resource.stubs(:purging?).returns true
      @resource.stubs(:deleting?).returns true
    end

    it "should be true if the resource is not being purged" do
      @resource.expects(:purging?).returns false
      @harness.should be_allow_changes(@resource)
    end

    it "should be true if the resource is not being deleted" do
      @resource.expects(:deleting?).returns false
      @harness.should be_allow_changes(@resource)
    end

    it "should be true if the resource has no dependents" do
      @harness.relationship_graph.expects(:dependents).with(@resource).returns []
      @harness.should be_allow_changes(@resource)
    end

    it "should be true if all dependents are being deleted" do
      dep = stub 'dependent', :deleting? => true
      @harness.relationship_graph.expects(:dependents).with(@resource).returns [dep]
      @resource.expects(:purging?).returns true
      @harness.should be_allow_changes(@resource)
    end

    it "should be false if the resource's dependents are not being deleted" do
      dep = stub 'dependent', :deleting? => false, :ref => "myres"
      @resource.expects(:warning)
      @harness.relationship_graph.expects(:dependents).with(@resource).returns [dep]
      @harness.should_not be_allow_changes(@resource)
    end
  end

  describe "when finding the schedule" do
    before do
      @catalog = Puppet::Resource::Catalog.new
      @resource.catalog = @catalog
    end

    it "should warn and return nil if the resource has no catalog" do
      @resource.catalog = nil
      @resource.expects(:warning)

      @harness.schedule(@resource).should be_nil
    end

    it "should return nil if the resource specifies no schedule" do
      @harness.schedule(@resource).should be_nil
    end

    it "should fail if the named schedule cannot be found" do
      @resource[:schedule] = "whatever"
      @resource.expects(:fail)
      @harness.schedule(@resource)
    end

    it "should return the named schedule if it exists" do
      sched = Puppet::Type.type(:schedule).new(:name => "sched")
      @catalog.add_resource(sched)
      @resource[:schedule] = "sched"
      @harness.schedule(@resource).to_s.should == sched.to_s
    end
  end

  describe "when determining if a resource is scheduled" do
    before do
      @catalog = Puppet::Resource::Catalog.new
      @resource.catalog = @catalog
    end

    it "should return true if 'ignoreschedules' is set" do
      Puppet[:ignoreschedules] = true
      @resource[:schedule] = "meh"
      @harness.should be_scheduled(@resource)
    end

    it "should return true if the resource has no schedule set" do
      @harness.should be_scheduled(@resource)
    end

    it "should return the result of matching the schedule with the cached 'checked' time if a schedule is set" do
      t = Time.now
      @harness.expects(:cached).with(@resource, :checked).returns(t)

      sched = Puppet::Type.type(:schedule).new(:name => "sched")
      @catalog.add_resource(sched)
      @resource[:schedule] = "sched"

      sched.expects(:match?).with(t.to_i).returns "feh"

      @harness.scheduled?(@resource).should == "feh"
    end
  end

  it "should be able to cache data in the Storage module" do
    data = {}
    Puppet::Util::Storage.expects(:cache).with(@resource).returns data
    @harness.cache(@resource, :foo, "something")

    data[:foo].should == "something"
  end

  it "should be able to retrieve data from the cache" do
    data = {:foo => "other"}
    Puppet::Util::Storage.expects(:cache).with(@resource).returns data
    @harness.cached(@resource, :foo).should == "other"
  end
end
