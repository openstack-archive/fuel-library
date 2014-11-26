require 'spec_helper'

describe Puppet::Type.type(:service).provider(:pacemaker) do

  let(:resource) { Puppet::Type.type(:service).new(:name => title,  :provider=> :pacemaker) }
  let(:provider) { resource.provider }
  let(:title) { 'myservice' }
  let(:full_name) { 'clone-p_myservice' }
  let(:name) { 'p_myservice' }
  let(:hostname) { 'mynode' }

  before :each do
    @class = provider

    @class.stubs(:title).returns(title)
    @class.stubs(:hostname).returns(hostname)
    @class.stubs(:name).returns(name)
    @class.stubs(:full_name).returns(full_name)
    @class.stubs(:basic_service_name).returns(title)

    @class.stubs(:cib_reset).returns(true)

    @class.stubs(:wait_for_online).returns(true)
    @class.stubs(:cleanup_with_wait).returns(true)
    @class.stubs(:wait_for_start).returns(true)
    @class.stubs(:wait_for_stop).returns(true)

    @class.stubs(:disable_basic_service).returns(true)
    @class.stubs(:get_primitive_puppet_status).returns(:started)
    @class.stubs(:get_primitive_puppet_enable).returns(:true)

    @class.stubs(:primitive_is_managed?).returns(true)
    @class.stubs(:primitive_is_running?).returns(true)
    @class.stubs(:primitive_has_failures?).returns(false)
    @class.stubs(:primitive_is_complex?).returns(false)
    @class.stubs(:primitive_is_multistate?).returns(false)
    @class.stubs(:primitive_is_clone?).returns(false)

    @class.stubs(:unban_primitive).returns(true)
    @class.stubs(:ban_primitive).returns(true)
    @class.stubs(:start_primitive).returns(true)
    @class.stubs(:stop_primitive).returns(true)
    @class.stubs(:enable).returns(true)
    @class.stubs(:disable).returns(true)

    @class.stubs(:constraint_location_add).returns(true)
    @class.stubs(:constraint_location_remove).returns(true)

    @class.stubs(:get_cluster_debug_report).returns(true)
  end

  context 'service name mangling' do
    it 'uses title as the service name if it is found in CIB' do
      @class.unstub(:name)
      @class.stubs(:primitive_exists?).with(title).returns(true)
      expect(@class.name).to eq(title)
    end

    it 'uses "p_" prefix with name if found name with prefix' do
      @class.unstub(:name)
      @class.stubs(:primitive_exists?).with(title).returns(false)
      @class.stubs(:primitive_exists?).with(name).returns(true)
      expect(@class.name).to eq(name)
    end

    it 'uses name without "p_" to disable basic service' do
      @class.stubs(:name).returns(name)
      expect(@class.basic_service_name).to eq(title)
    end
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

    it 'gets service status locally' do
      @class.expects(:get_primitive_puppet_status).with name, hostname
      @class.status
    end

  end

  context '#start' do
    it 'tries to enable service if it is not enabled to work with it' do
      @class.stubs(:primitive_is_managed?).returns(false)
      @class.expects(:enable).once
      @class.start
      @class.stubs(:primitive_is_managed?).returns(true)
      @class.expects(:enable).never
      @class.start
    end

    it 'tries to disable a basic service with the same name' do
      @class.expects(:disable_basic_service)
      @class.start
    end

    it 'should cleanup a primitive only if there are errors' do
      @class.stubs(:primitive_has_failures?).returns(true)
      @class.expects(:cleanup_with_wait).once
      @class.start
      @class.stubs(:primitive_has_failures?).returns(false)
      @class.expects(:cleanup_with_wait).never
      @class.start
    end

    it 'tries to unban the service on the node by the name' do
      @class.expects(:unban_primitive).with(name, hostname)
      @class.start
    end

    it 'tries to start the service by its name' do
      @class.expects(:start_primitive).with(name)
      @class.start
    end

    it 'adds a location constraint for the service by its name' do
      @class.expects(:constraint_location_add).with(name, hostname)
      @class.start
    end

    it 'waits for the service to start locally if primitive is clone' do
      @class.stubs(:primitive_is_clone?).returns(true)
      @class.stubs(:primitive_is_multistate?).returns(false)
      @class.stubs(:primitive_is_complex?).returns(true)
      @class.expects(:wait_for_start).with name
      @class.start
    end

    it 'waits for the service to start master anywhere if primitive is multistate' do
      @class.stubs(:primitive_is_clone?).returns(false)
      @class.stubs(:primitive_is_multistate?).returns(true)
      @class.stubs(:primitive_is_complex?).returns(true)
      @class.expects(:wait_for_master).with name
      @class.start
    end

    it 'waits for the service to start anywhere if primitive is simple' do
      @class.stubs(:primitive_is_clone?).returns(false)
      @class.stubs(:primitive_is_multistate?).returns(false)
      @class.stubs(:primitive_is_complex?).returns(false)
      @class.expects(:wait_for_start).with name
      @class.start
    end
  end

  context '#stop' do
    it 'tries to enable service if it is not enabled to work with it' do
      @class.stubs(:primitive_is_managed?).returns(false)
      @class.expects(:enable).once
      @class.start
      @class.stubs(:primitive_is_managed?).returns(true)
      @class.expects(:enable).never
      @class.start
    end

    it 'should cleanup a primitive only if there are errors' do
      @class.stubs(:primitive_has_failures?).returns(true)
      @class.expects(:cleanup_with_wait).once
      @class.start
      @class.stubs(:primitive_has_failures?).returns(false)
      @class.expects(:cleanup_with_wait).never
      @class.start
    end

    it 'uses Ban to stop the service and waits for it to stop locally if service is complex' do
      @class.stubs(:primitive_is_complex?).returns(true)
      @class.expects(:wait_for_stop).with name, hostname
      @class.expects(:ban_primitive).with name, hostname
      @class.stop
    end

    it 'uses Stop to stop the service and waits for it to stop globally if service is simple' do
      @class.stubs(:primitive_is_complex?).returns(false)
      @class.expects(:wait_for_stop).with name
      @class.expects(:stop_primitive).with name
      @class.stop
    end
  end

  context '#restart' do
    it 'does not stop or start the service if it is not locally running' do
      @class.stubs(:primitive_is_running?).with(name, hostname).returns(false)
      @class.expects(:stop).never
      @class.expects(:start).never
      @class.restart
    end

    it 'stops and start the service if it is locally running' do
      @class.stubs(:primitive_is_running?).with(name, hostname).returns(true)
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

