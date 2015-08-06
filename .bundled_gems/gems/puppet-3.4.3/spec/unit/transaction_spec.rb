#! /usr/bin/env ruby
require 'spec_helper'
require 'matchers/include_in_order'
require 'puppet_spec/compiler'

require 'puppet/transaction'
require 'fileutils'

describe Puppet::Transaction do
  include PuppetSpec::Files
  include PuppetSpec::Compiler

  def catalog_with_resource(resource)
    catalog = Puppet::Resource::Catalog.new
    catalog.add_resource(resource)
    catalog
  end

  def transaction_with_resource(resource)
    transaction = Puppet::Transaction.new(catalog_with_resource(resource), nil, Puppet::Graph::RandomPrioritizer.new)
    transaction
  end

  before do
    @basepath = make_absolute("/what/ever")
    @transaction = Puppet::Transaction.new(Puppet::Resource::Catalog.new, nil, Puppet::Graph::RandomPrioritizer.new)
  end

  it "should be able to look resource status up by resource reference" do
    resource = Puppet::Type.type(:notify).new :title => "foobar"
    transaction = transaction_with_resource(resource)
    transaction.evaluate

    transaction.resource_status(resource.to_s).should be_changed
  end

  # This will basically only ever be used during testing.
  it "should automatically create resource statuses if asked for a non-existent status" do
    resource = Puppet::Type.type(:notify).new :title => "foobar"
    @transaction.resource_status(resource).should be_instance_of(Puppet::Resource::Status)
  end

  it "should add provided resource statuses to its report" do
    resource = Puppet::Type.type(:notify).new :title => "foobar"
    transaction = transaction_with_resource(resource)
    transaction.evaluate

    status = transaction.resource_status(resource)
    transaction.report.resource_statuses[resource.to_s].should equal(status)
  end

  it "should not consider there to be failed resources if no statuses are marked failed" do
    resource = Puppet::Type.type(:notify).new :title => "foobar"
    transaction = transaction_with_resource(resource)
    transaction.evaluate

    transaction.should_not be_any_failed
  end

  it "should use the provided report object" do
    report = Puppet::Transaction::Report.new("apply")
    transaction = Puppet::Transaction.new(Puppet::Resource::Catalog.new, report, nil)

    transaction.report.should == report
  end

  it "should create a report if none is provided" do
    transaction = Puppet::Transaction.new(Puppet::Resource::Catalog.new, nil, nil)

    transaction.report.should be_kind_of Puppet::Transaction::Report
  end

  describe "when initializing" do
    it "should create an event manager" do
      @transaction = Puppet::Transaction.new(Puppet::Resource::Catalog.new, nil, nil)
      @transaction.event_manager.should be_instance_of(Puppet::Transaction::EventManager)
      @transaction.event_manager.transaction.should equal(@transaction)
    end

    it "should create a resource harness" do
      @transaction = Puppet::Transaction.new(Puppet::Resource::Catalog.new, nil, nil)
      @transaction.resource_harness.should be_instance_of(Puppet::Transaction::ResourceHarness)
      @transaction.resource_harness.transaction.should equal(@transaction)
    end

    it "should set retrieval time on the report" do
      catalog = Puppet::Resource::Catalog.new
      report = Puppet::Transaction::Report.new("apply")
      catalog.retrieval_duration = 5

      report.expects(:add_times).with(:config_retrieval, 5)

      transaction = Puppet::Transaction.new(catalog, report, nil)
    end
  end

  describe "when evaluating a resource" do
    before do
      @catalog = Puppet::Resource::Catalog.new
      @resource = Puppet::Type.type(:file).new :path => @basepath
      @catalog.add_resource(@resource)

      @transaction = Puppet::Transaction.new(@catalog, nil, Puppet::Graph::RandomPrioritizer.new)
      @transaction.stubs(:skip?).returns false
    end

    it "should process events" do
      @transaction.event_manager.expects(:process_events).with(@resource)

      @transaction.evaluate
    end

    describe "and the resource should be skipped" do
      before do
        @transaction.expects(:skip?).with(@resource).returns true
      end

      it "should mark the resource's status as skipped" do
        @transaction.evaluate
        @transaction.resource_status(@resource).should be_skipped
      end
    end
  end

  describe "when applying a resource" do
    before do
      @catalog = Puppet::Resource::Catalog.new
      @resource = Puppet::Type.type(:file).new :path => @basepath
      @catalog.add_resource(@resource)
      @status = Puppet::Resource::Status.new(@resource)

      @transaction = Puppet::Transaction.new(@catalog, nil, Puppet::Graph::RandomPrioritizer.new)
      @transaction.event_manager.stubs(:queue_events)
    end

    it "should use its resource harness to apply the resource" do
      @transaction.resource_harness.expects(:evaluate).with(@resource)
      @transaction.evaluate
    end

    it "should add the resulting resource status to its status list" do
      @transaction.resource_harness.stubs(:evaluate).returns(@status)
      @transaction.evaluate
      @transaction.resource_status(@resource).should be_instance_of(Puppet::Resource::Status)
    end

    it "should queue any events added to the resource status" do
      @transaction.resource_harness.stubs(:evaluate).returns(@status)
      @status.expects(:events).returns %w{a b}
      @transaction.event_manager.expects(:queue_events).with(@resource, ["a", "b"])
      @transaction.evaluate
    end

    it "should log and skip any resources that cannot be applied" do
      @resource.expects(:properties).raises ArgumentError
      @transaction.evaluate
      @transaction.report.resource_statuses[@resource.to_s].should be_failed
    end

    it "should report any_failed if any resources failed" do
      @resource.expects(:properties).raises ArgumentError
      @transaction.evaluate

      expect(@transaction).to be_any_failed
    end
  end

  describe "#unblock" do
    let(:graph) { @transaction.relationship_graph }
    let(:resource) { Puppet::Type.type(:notify).new(:name => 'foo') }

    it "should calculate the number of blockers if it's not known" do
      graph.add_vertex(resource)
      3.times do |i|
        other = Puppet::Type.type(:notify).new(:name => i.to_s)
        graph.add_vertex(other)
        graph.add_edge(other, resource)
      end

      graph.unblock(resource)

      graph.blockers[resource].should == 2
    end

    it "should decrement the number of blockers if there are any" do
      graph.blockers[resource] = 40

      graph.unblock(resource)

      graph.blockers[resource].should == 39
    end

    it "should warn if there are no blockers" do
      vertex = stub('vertex')
      vertex.expects(:warning).with "appears to have a negative number of dependencies"
      graph.blockers[vertex] = 0

      graph.unblock(vertex)
    end

    it "should return true if the resource is now unblocked" do
      graph.blockers[resource] = 1

      graph.unblock(resource).should == true
    end

    it "should return false if the resource is still blocked" do
      graph.blockers[resource] = 2

      graph.unblock(resource).should == false
    end
  end

  describe "when traversing" do
    let(:path) { tmpdir('eval_generate') }
    let(:resource) { Puppet::Type.type(:file).new(:path => path, :recurse => true) }

    before :each do
      @transaction.catalog.add_resource(resource)
    end

    it "should yield the resource even if eval_generate is called" do
      Puppet::Transaction::AdditionalResourceGenerator.any_instance.expects(:eval_generate).with(resource).returns true

      yielded = false
      @transaction.evaluate do |res|
        yielded = true if res == resource
      end

      yielded.should == true
    end

    it "should prefetch the provider if necessary" do
      @transaction.expects(:prefetch_if_necessary).with(resource)

      @transaction.evaluate {}
    end

    it "traverses independent resources before dependent resources" do
      dependent = Puppet::Type.type(:notify).new(:name => "hello", :require => resource)
      @transaction.catalog.add_resource(dependent)

      seen = []
      @transaction.evaluate do |res|
        seen << res
      end

      expect(seen).to include_in_order(resource, dependent)
    end

    it "traverses completely independent resources in the order they appear in the catalog" do
      independent = Puppet::Type.type(:notify).new(:name => "hello", :require => resource)
      @transaction.catalog.add_resource(independent)

      seen = []
      @transaction.evaluate do |res|
        seen << res
      end

      expect(seen).to include_in_order(resource, independent)
    end

    it "should fail unsuitable resources and go on if it gets blocked" do
      dependent = Puppet::Type.type(:notify).new(:name => "hello", :require => resource)
      @transaction.catalog.add_resource(dependent)

      resource.stubs(:suitable?).returns false

      evaluated = []
      @transaction.evaluate do |res|
        evaluated << res
      end

      # We should have gone on to evaluate the children
      evaluated.should == [dependent]
      @transaction.resource_status(resource).should be_failed
    end
  end

  describe "when generating resources before traversal" do
    let(:catalog) { Puppet::Resource::Catalog.new }
    let(:transaction) { Puppet::Transaction.new(catalog, nil, Puppet::Graph::RandomPrioritizer.new) }
    let(:generator) { Puppet::Type.type(:notify).new :title => "generator" }
    let(:generated) do
      %w[a b c].map { |name| Puppet::Type.type(:notify).new(:name => name) }
    end

    before :each do
      catalog.add_resource generator
      generator.stubs(:generate).returns generated
    end

    it "should call 'generate' on all created resources" do
      generated.each { |res| res.expects(:generate) }

      transaction.evaluate
    end

    it "should finish all resources" do
      generated.each { |res| res.expects(:finish) }

      transaction.evaluate
    end

    it "should copy all tags to the newly generated resources" do
      generator.tag('one', 'two')

      transaction.evaluate

      generated.each do |res|
        res.must be_tagged(*generator.tags)
      end
    end
  end

  describe "when skipping a resource" do
    before :each do
      @resource = Puppet::Type.type(:notify).new :name => "foo"
      @catalog = Puppet::Resource::Catalog.new
      @resource.catalog = @catalog
      @transaction = Puppet::Transaction.new(@catalog, nil, nil)
    end

    it "should skip resource with missing tags" do
      @transaction.stubs(:missing_tags?).returns(true)
      @transaction.should be_skip(@resource)
    end

    it "should skip unscheduled resources" do
      @transaction.stubs(:scheduled?).returns(false)
      @transaction.should be_skip(@resource)
    end

    it "should skip resources with failed dependencies" do
      @transaction.stubs(:failed_dependencies?).returns(true)
      @transaction.should be_skip(@resource)
    end

    it "should skip virtual resource" do
      @resource.stubs(:virtual?).returns true
      @transaction.should be_skip(@resource)
    end

    it "should skip device only resouce on normal host" do
      @resource.stubs(:appliable_to_host?).returns false
      @resource.stubs(:appliable_to_device?).returns true
      @transaction.for_network_device = false
      @transaction.should be_skip(@resource)
    end

    it "should not skip device only resouce on remote device" do
      @resource.stubs(:appliable_to_host?).returns false
      @resource.stubs(:appliable_to_device?).returns true
      @transaction.for_network_device = true
      @transaction.should_not be_skip(@resource)
    end

    it "should skip host resouce on device" do
      @resource.stubs(:appliable_to_host?).returns true
      @resource.stubs(:appliable_to_device?).returns false
      @transaction.for_network_device = true
      @transaction.should be_skip(@resource)
    end

    it "should not skip resouce available on both device and host when on device" do
      @resource.stubs(:appliable_to_host?).returns true
      @resource.stubs(:appliable_to_device?).returns true
      @transaction.for_network_device = true
      @transaction.should_not be_skip(@resource)
    end

    it "should not skip resouce available on both device and host when on host" do
      @resource.stubs(:appliable_to_host?).returns true
      @resource.stubs(:appliable_to_device?).returns true
      @transaction.for_network_device = false
      @transaction.should_not be_skip(@resource)
    end
  end

  describe "when determining if tags are missing" do
    before :each do
      @resource = Puppet::Type.type(:notify).new :name => "foo"
      @catalog = Puppet::Resource::Catalog.new
      @resource.catalog = @catalog
      @transaction = Puppet::Transaction.new(@catalog, nil, nil)

      @transaction.stubs(:ignore_tags?).returns false
    end

    it "should not be missing tags if tags are being ignored" do
      @transaction.expects(:ignore_tags?).returns true

      @resource.expects(:tagged?).never

      @transaction.should_not be_missing_tags(@resource)
    end

    it "should not be missing tags if the transaction tags are empty" do
      @transaction.tags = []
      @resource.expects(:tagged?).never
      @transaction.should_not be_missing_tags(@resource)
    end

    it "should otherwise let the resource determine if it is missing tags" do
      tags = ['one', 'two']
      @transaction.tags = tags
      @transaction.should be_missing_tags(@resource)
    end
  end

  describe "when determining if a resource should be scheduled" do
    before :each do
      @resource = Puppet::Type.type(:notify).new :name => "foo"
      @catalog = Puppet::Resource::Catalog.new
      @catalog.add_resource(@resource)
      @transaction = Puppet::Transaction.new(@catalog, nil, Puppet::Graph::RandomPrioritizer.new)
    end

    it "should always schedule resources if 'ignoreschedules' is set" do
      @transaction.ignoreschedules = true
      @transaction.resource_harness.expects(:scheduled?).never

      @transaction.evaluate
      @transaction.resource_status(@resource).should be_changed
    end

    it "should let the resource harness determine whether the resource should be scheduled" do
      @transaction.resource_harness.expects(:scheduled?).with(@resource).returns "feh"

      @transaction.evaluate
    end
  end

  describe "when prefetching" do
    let(:catalog) { Puppet::Resource::Catalog.new }
    let(:transaction) { Puppet::Transaction.new(catalog, nil, nil) }
    let(:resource) { Puppet::Type.type(:sshkey).new :title => "foo", :name => "bar", :type => :dsa, :key => "eh", :provider => :parsed }
    let(:resource2) { Puppet::Type.type(:package).new :title => "blah", :provider => "apt" }

    before :each do
      catalog.add_resource resource
      catalog.add_resource resource2
    end

    it "should match resources by name, not title" do
      resource.provider.class.expects(:prefetch).with("bar" => resource)

      transaction.prefetch_if_necessary(resource)
    end

    it "should not prefetch a provider which has already been prefetched" do
      transaction.prefetched_providers[:sshkey][:parsed] = true

      resource.provider.class.expects(:prefetch).never

      transaction.prefetch_if_necessary(resource)
    end

    it "should mark the provider prefetched" do
      resource.provider.class.stubs(:prefetch)

      transaction.prefetch_if_necessary(resource)

      transaction.prefetched_providers[:sshkey][:parsed].should be_true
    end

    it "should prefetch resources without a provider if prefetching the default provider" do
      other = Puppet::Type.type(:sshkey).new :name => "other"

      other.instance_variable_set(:@provider, nil)

      catalog.add_resource other

      resource.provider.class.expects(:prefetch).with('bar' => resource, 'other' => other)

      transaction.prefetch_if_necessary(resource)
    end
  end

  describe "during teardown" do
    before :each do
      @catalog = Puppet::Resource::Catalog.new
      @transaction = Puppet::Transaction.new(@catalog, nil, Puppet::Graph::RandomPrioritizer.new)
    end

    it "should call ::post_resource_eval on provider classes that support it" do
      @resource = Puppet::Type.type(:notify).new :title => "foo"
      @catalog.add_resource @resource

      # 'expects' will cause 'respond_to?(:post_resource_eval)' to return true
      @resource.provider.class.expects(:post_resource_eval)
      @transaction.evaluate
    end

    it "should call ::post_resource_eval even if other providers' ::post_resource_eval fails" do
      @resource3 = Puppet::Type.type(:user).new :title => "bloo"
      @resource3.provider.class.stubs(:post_resource_eval).raises
      @resource4 = Puppet::Type.type(:notify).new :title => "blob"
      @resource4.provider.class.stubs(:post_resource_eval).raises
      @catalog.add_resource @resource3
      @catalog.add_resource @resource4

      # ruby's Set does not guarantee ordering, so both resource3 and resource4
      # need to expect post_resource_eval, rather than just the 'first' one.
      @resource3.provider.class.expects(:post_resource_eval)
      @resource4.provider.class.expects(:post_resource_eval)

      @transaction.evaluate
    end

    it "should call ::post_resource_eval even if one of the resources fails" do
      @resource3 = Puppet::Type.type(:notify).new :title => "bloo"
      @resource3.stubs(:retrieve_resource).raises
      @catalog.add_resource @resource3

      @resource3.provider.class.expects(:post_resource_eval)

      @transaction.evaluate
    end
  end

  describe 'when checking application run state' do
    before do
      @catalog = Puppet::Resource::Catalog.new
      @transaction = Puppet::Transaction.new(@catalog, nil, Puppet::Graph::RandomPrioritizer.new)
    end

    context "when stop is requested" do
      before :each do
        Puppet::Application.stubs(:stop_requested?).returns(true)
      end

      it 'should return true for :stop_processing?' do
        @transaction.should be_stop_processing
      end

      it 'always evaluates non-host_config catalogs' do
        @catalog.host_config = false
        @transaction.should_not be_stop_processing
      end
    end

    it 'should return false for :stop_processing? if Puppet::Application.stop_requested? is false' do
      Puppet::Application.stubs(:stop_requested?).returns(false)
      @transaction.stop_processing?.should be_false
    end

    describe 'within an evaluate call' do
      before do
        @resource = Puppet::Type.type(:notify).new :title => "foobar"
        @catalog.add_resource @resource
        @transaction.stubs(:add_dynamically_generated_resources)
      end

      it 'should stop processing if :stop_processing? is true' do
        @transaction.stubs(:stop_processing?).returns(true)
        @transaction.expects(:eval_resource).never
        @transaction.evaluate
      end

      it 'should continue processing if :stop_processing? is false' do
        @transaction.stubs(:stop_processing?).returns(false)
        @transaction.expects(:eval_resource).returns(nil)
        @transaction.evaluate
      end
    end
  end

  it "errors with a dependency cycle for a resource that requires itself" do
    expect do
      apply_compiled_manifest(<<-MANIFEST)
        notify { cycle: require => Notify[cycle] }
      MANIFEST
    end.to raise_error(Puppet::Error, /Found 1 dependency cycle:.*\(Notify\[cycle\] => Notify\[cycle\]\)/m)
  end

  it "errors with a dependency cycle for a self-requiring resource also required by another resource" do
    expect do
      apply_compiled_manifest(<<-MANIFEST)
        notify { cycle: require => Notify[cycle] }
        notify { other: require => Notify[cycle] }
      MANIFEST
    end.to raise_error(Puppet::Error, /Found 1 dependency cycle:.*\(Notify\[cycle\] => Notify\[cycle\]\)/m)
  end

  it "errors with a dependency cycle for a resource that requires itself and another resource" do
    expect do
      apply_compiled_manifest(<<-MANIFEST)
        notify { cycle:
          require => [Notify[other], Notify[cycle]]
        }
        notify { other: }
      MANIFEST
    end.to raise_error(Puppet::Error, /Found 1 dependency cycle:.*\(Notify\[cycle\] => Notify\[cycle\]\)/m)
  end

  it "errors with a dependency cycle for a resource that is later modified to require itself" do
    expect do
      apply_compiled_manifest(<<-MANIFEST)
        notify { cycle: }
        Notify <| title == 'cycle' |> {
          require => Notify[cycle]
        }
      MANIFEST
    end.to raise_error(Puppet::Error, /Found 1 dependency cycle:.*\(Notify\[cycle\] => Notify\[cycle\]\)/m)
  end

  it "reports a changed resource with a successful run" do
    transaction = apply_compiled_manifest("notify { one: }")

    transaction.report.status.should == 'changed'
    transaction.report.resource_statuses['Notify[one]'].should be_changed
  end

  describe "when interrupted" do
    it "marks unprocessed resources as skipped" do
      Puppet::Application.stop!

      transaction = apply_compiled_manifest(<<-MANIFEST)
        notify { a: } ->
        notify { b: }
      MANIFEST

      transaction.report.resource_statuses['Notify[a]'].should be_skipped
      transaction.report.resource_statuses['Notify[b]'].should be_skipped
    end
  end
end

describe Puppet::Transaction, " when determining tags" do
  before do
    @config = Puppet::Resource::Catalog.new
    @transaction = Puppet::Transaction.new(@config, nil, nil)
  end

  it "should default to the tags specified in the :tags setting" do
    Puppet[:tags] = "one"
    @transaction.should be_tagged("one")
  end

  it "should split tags based on ','" do
    Puppet[:tags] = "one,two"
    @transaction.should be_tagged("one")
    @transaction.should be_tagged("two")
  end

  it "should use any tags set after creation" do
    Puppet[:tags] = ""
    @transaction.tags = %w{one two}
    @transaction.should be_tagged("one")
    @transaction.should be_tagged("two")
  end

  it "should always convert assigned tags to an array" do
    @transaction.tags = "one::two"
    @transaction.should be_tagged("one::two")
  end

  it "should accept a comma-delimited string" do
    @transaction.tags = "one, two"
    @transaction.should be_tagged("one")
    @transaction.should be_tagged("two")
  end

  it "should accept an empty string" do
    @transaction.tags = "one, two"
    @transaction.should be_tagged("one")
    @transaction.tags = ""
    @transaction.should_not be_tagged("one")
  end
end
