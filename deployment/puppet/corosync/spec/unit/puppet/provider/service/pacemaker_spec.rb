require 'spec_helper'

describe Puppet::Type.type(:service).provider(:pacemaker) do

  let(:resource) { Puppet::Type.type(:service).new(:name => service_name,  :provider=> :pacemaker) }
  let(:provider) { resource.provider }
  let(:service_name) { 'myservice' }
  let(:full_service_name) { 'clone-myservice' }
  let(:node_name) { 'mynode' }

  before :each do
    @class = provider

    @class.stubs(:uname).returns(node_name)
    @class.stubs(:hostname).returns(node_name)
    @class.stubs(:name).returns(service_name)
    @class.stubs(:full_name).returns(full_service_name)

    @class.stubs(:wait_for_online).returns(true)
    @class.stubs(:cib_reset).returns(true)
    @class.stubs(:cleanup_with_wait).returns(true)
    @class.stubs(:wait_for_start).returns(true)
    @class.stubs(:wait_for_stop).returns(true)
    @class.stubs(:disable_basic_service).returns(true)
    @class.stubs(:get_primitive_puppet_status).returns(:started)

    @class.stubs(:primitive_has_failures?).returns(false)
    @class.stubs(:primitive_is_complex?).returns(true)

    @class.stubs(:unban_primitive).returns(true)
    @class.stubs(:ban_primitive).returns(true)
    @class.stubs(:start_primitive).returns(true)
    @class.stubs(:stop_primitive).returns(true)
    @class.stubs(:enable).returns(true)
    @class.stubs(:disable).returns(true)
    @class.stubs(:enabled?).returns(:true)

    @class.stubs(:constraint_location_add).returns(true)
    @class.stubs(:constraint_location_remove).returns(true)

  end

  context '#status' do
    it 'should wait for pacemaker to become online' do
      @class.expects(:wait_for_online)
      @class.status
    end

    it 'should reset cib mnemoization on every call' do
      @class.expects(:cib_reset)
      @class.status
    end

    it 'should cleanup a resource only if there are errors' do
      @class.stubs(:primitive_has_failures?).returns(true)
      @class.expects(:cleanup_with_wait)
      @class.status
      @class.stubs(:primitive_has_failures?).returns(false)
      @class.expects(:cleanup_with_wait).never
      @class.status
    end

    it 'gets service status either globally or locally if called with node name' do
      @class.expects(:get_primitive_puppet_status).with service_name, node_name
      @class.status node_name
      @class.expects(:get_primitive_puppet_status).with service_name, nil
      @class.status
    end

    it 'tries to disable a basic service with the same name' do
      @class.expects(:disable_basic_service)
      @class.status
    end

  end

  context '#start' do
    it 'tries to enable service if it is not enabled to work with it' do
      @class.stubs(:enabled?).returns(false)
      @class.expects(:enable)
      @class.start
      @class.stubs(:enabled?).returns(true)
      @class.expects(:enable).never
      @class.start
    end

    it 'should cleanup a primitive only if there are errors' do
      @class.stubs(:primitive_has_failures?).returns(true)
      @class.expects(:cleanup_with_wait)
      @class.start
      @class.stubs(:primitive_has_failures?).returns(false)
      @class.expects(:cleanup_with_wait).never
      @class.start
    end

    it 'tries to unban the service by the short name' do
      @class.expects(:unban_primitive).with(service_name)
      @class.start
    end

    it 'tries to start the service by its full name' do
      @class.expects(:start_primitive).with(full_service_name)
      @class.start
    end

    it 'adds a location constraint for the service by the full name' do
      @class.expects(:constraint_location_add).with(full_service_name, node_name)
      @class.start
    end

    it 'waits for te service to start locally if primitive is complex or globally if simple' do
      @class.stubs(:primitive_is_complex?).returns(true)
      @class.expects(:wait_for_start).with service_name, node_name
      @class.start
      @class.stubs(:primitive_is_complex?).returns(false)
      @class.expects(:wait_for_start).with service_name
      @class.start
    end

  end

  context '#stop' do
    it 'tries to enable service if it is not enabled to work with it' do
      @class.stubs(:enabled?).returns(:false)
      @class.expects(:enable)
      @class.start
      @class.stubs(:enabled?).returns(:true)
      @class.expects(:enable).never
      @class.start
    end

    it 'should cleanup a primitive only if there are errors' do
      @class.stubs(:primitive_has_failures?).returns(true)
      @class.expects(:cleanup_with_wait)
      @class.start
      @class.stubs(:primitive_has_failures?).returns(false)
      @class.expects(:cleanup_with_wait).never
      @class.start
    end

    it 'uses Ban to stop the service and waits for it to stop locally if service is complex' do
      @class.stubs(:primitive_is_complex?).returns(true)
      @class.expects(:wait_for_stop).with service_name, node_name
      @class.expects(:ban_primitive).with service_name
      @class.stop
    end

    it 'uses Stop to stop the service and waits for it to stop globally if service is simple' do
      @class.stubs(:primitive_is_complex?).returns(false)
      @class.expects(:wait_for_stop).with service_name
      @class.expects(:stop_primitive).with full_service_name
      @class.stop
    end

  end

  context '#restart' do
    it 'stops and start the service' do
      restart_sequence = sequence('restart')
      @class.expects(:stop).in_sequence(restart_sequence)
      @class.expects(:start).in_sequence(restart_sequence)
      @class.restart
    end
  end

  context 'basic service handling' do
    before :each do
      @class.unstub(:disable_basic_service)
      @class.extra_provider.stubs(:enableable?).returns true
      @class.extra_provider.stubs(:enabled?).returns :true
      @class.extra_provider.stubs(:disable).returns true
      @class.extra_provider.stubs(:stop).returns true
      @class.extra_provider.stubs(:status).returns :running
    end

    it 'tries to disable the basic service if it is enabled' do
      @class.extra_provider.expects(:disable)
      @class.disable_basic_service
    end

    it 'tries to stop the service if it is running' do
      @class.extra_provider.expects(:stop)
      @class.disable_basic_service
    end
  end

end

