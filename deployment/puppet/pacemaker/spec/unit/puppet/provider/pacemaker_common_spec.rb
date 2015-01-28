require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), '../../../../lib/puppet/provider/pacemaker_common.rb'))

describe Puppet::Provider::Pacemaker_common do

  cib_xml_file = File.join File.dirname(__FILE__), 'cib.xml'

  let(:raw_cib) do
    File.read cib_xml_file
  end

  let(:resources_regexp) do
    %r{nova|cinder|glance|keystone|neutron|sahara|murano|ceilometer|heat|swift}
  end

  ###########################

  #-> Cloned primitive 'clone_p_neutron-plugin-openvswitch-agent' global status: start
  #node-1: start | node-2: stop | node-3: stop
  #-> Cloned primitive 'clone_ping_vip__public' global status: start
  #node-1: start | node-2: start | node-3: start
  #-> Cloned primitive 'clone_p_neutron-metadata-agent' global status: start
  #node-1: start | node-2: stop | node-3: stop
  #-> Simple primitive 'vip__management' global status: start
  #node-1: start | node-2: stop | node-3: stop
  #-> Cloned primitive 'clone_p_mysql' global status: start
  #node-1: start | node-2: start | node-3: stop
  #-> Multistate primitive 'master_p_rabbitmq-server' global status: master
  #node-1: master | node-2: start | node-3: stop
  #-> Cloned primitive 'clone_p_haproxy' global status: start
  #node-1: start | node-2: start | node-3: stop
  #-> Simple primitive 'p_ceilometer-alarm-evaluator' global status: stop
  #node-1: stop | node-2: stop (FAIL) | node-3: stop (FAIL)
  #-> Simple primitive 'p_ceilometer-agent-central' global status: stop
  #node-1: stop | node-2: stop (FAIL) | node-3: stop (FAIL)
  #-> Cloned primitive 'clone_p_neutron-l3-agent' global status: start
  #node-1: start | node-2: stop | node-3: stop
  #-> Simple primitive 'p_neutron-dhcp-agent' global status: start
  #node-1: start | node-2: stop | node-3: stop
  #-> Simple primitive 'vip__public' global status: start
  #node-1: start | node-2: stop | node-3: stop
  #-> Simple primitive 'p_heat-engine' global status: start
  #node-1: start | node-2: stop | node-3: stop

  before(:each) do
    @class = subject
    @class.stubs(:raw_cib).returns raw_cib
    @class.stubs(:pcs).returns true
  end

  context 'configuration parser' do
    it 'can obtain a CIB XML object' do
      expect(@class.cib.to_s).to include '<configuration>'
      expect(@class.cib.to_s).to include '<nodes>'
      expect(@class.cib.to_s).to include '<resources>'
      expect(@class.cib.to_s).to include '<status>'
      expect(@class.cib.to_s).to include '<operations>'
    end

    it 'can get primitives section of CIB XML' do
      expect(@class.cib_section_primitives).to be_a(Array)
      expect(@class.cib_section_primitives.first.to_s).to start_with '<primitive'
      expect(@class.cib_section_primitives.first.to_s).to end_with '</primitive>'
    end

    it 'can get primitives configuration' do
      expect(@class.primitives).to be_a Hash
      expect(@class.primitives['vip__public']).to be_a Hash
      expect(@class.primitives['vip__public']['meta_attributes']).to be_a Hash
      expect(@class.primitives['vip__public']['instance_attributes']).to be_a Hash
      expect(@class.primitives['vip__public']['instance_attributes']['ip']).to be_a Hash
      expect(@class.primitives['vip__public']['operations']).to be_a Hash
      expect(@class.primitives['vip__public']['meta_attributes']['resource-stickiness']).to be_a Hash
      expect(@class.primitives['vip__public']['operations']['vip__public-start-0']).to be_a Hash
    end

    it 'can determine is primitive is simple or complex' do
      expect(@class.primitive_is_complex? 'p_haproxy').to eq true
      expect(@class.primitive_is_complex? 'vip__management').to eq false
    end
  end

  context 'node status parser' do
    it 'can produce nodes structure' do
      expect(@class.nodes).to be_a Hash
      expect(@class.nodes['node-1']['primitives']['p_heat-engine']['status']).to eq('start')
      #puts @class.get_cluster_debug_report
    end

    it 'can determite a global primitive status' do
      expect(@class.primitive_status 'p_heat-engine').to eq('start')
      expect(@class.primitive_is_running? 'p_heat-engine').to eq true
      expect(@class.primitive_status 'p_ceilometer-agent-central').to eq('stop')
      expect(@class.primitive_is_running? 'p_ceilometer-agent-central').to eq false
      expect(@class.primitive_is_running? 'UNKNOWN').to eq nil
      expect(@class.primitive_status 'UNKNOWN').to eq nil
    end

    it 'can determine a local primitive status on a node' do
      expect(@class.primitive_status 'p_heat-engine', 'node-1').to eq('start')
      expect(@class.primitive_is_running? 'p_heat-engine', 'node-1').to eq true
      expect(@class.primitive_status 'p_heat-engine', 'node-2').to eq('stop')
      expect(@class.primitive_is_running? 'p_heat-engine', 'node-2').to eq false
      expect(@class.primitive_is_running? 'UNKNOWN', 'node-1').to eq nil
      expect(@class.primitive_status 'UNKNOWN', 'node-1').to eq nil
    end

    it 'can determine if primitive is managed or not' do
      expect(@class.primitive_is_managed? 'p_heat-engine').to eq true
      expect(@class.primitive_is_managed? 'p_haproxy').to eq true
      expect(@class.primitive_is_managed? 'UNKNOWN').to eq nil
    end

    it 'can determine if primitive is started or not' do
      expect(@class.primitive_is_started? 'p_heat-engine').to eq true
      expect(@class.primitive_is_started? 'p_haproxy').to eq true
      expect(@class.primitive_is_started? 'UNKNOWN').to eq nil
    end

    it 'can determine if primitive is failed or not globally' do
      expect(@class.primitive_has_failures? 'p_ceilometer-agent-central').to eq true
      expect(@class.primitive_has_failures? 'p_heat-engine').to eq false
      expect(@class.primitive_has_failures? 'UNKNOWN').to eq nil
    end

    it 'can determine if primitive is failed or not locally' do
      expect(@class.primitive_has_failures? 'p_ceilometer-agent-central', 'node-1').to eq false
      expect(@class.primitive_has_failures? 'p_ceilometer-agent-central', 'node-2').to eq true
      expect(@class.primitive_has_failures? 'p_heat-engine', 'node-1').to eq false
      expect(@class.primitive_has_failures? 'p_heat-engine', 'node-2').to eq false
      expect(@class.primitive_has_failures? 'UNKNOWN', 'node-1').to eq nil
    end

    it 'can determine that primitive is complex' do
      expect(@class.primitive_is_complex? 'p_haproxy').to eq true
      expect(@class.primitive_is_complex? 'p_heat-engine').to eq false
      expect(@class.primitive_is_complex? 'p_rabbitmq-server').to eq true
      expect(@class.primitive_is_complex? 'UNKNOWN').to eq nil
    end

    it 'can determine that primitive is multistate' do
      expect(@class.primitive_is_multistate? 'p_haproxy').to eq false
      expect(@class.primitive_is_multistate? 'p_heat-engine').to eq false
      expect(@class.primitive_is_multistate? 'p_rabbitmq-server').to eq true
      expect(@class.primitive_is_multistate? 'UNKNOWN').to eq nil
    end

    it 'can determine that primitive has master running' do
      expect(@class.primitive_has_master_running? 'p_rabbitmq-server').to eq true
      expect(@class.primitive_has_master_running? 'p_heat-engine').to eq false
      expect(@class.primitive_has_master_running? 'UNKNOWN').to eq nil
    end

    it 'can determine that primitive is clone' do
      expect(@class.primitive_is_clone? 'p_haproxy').to eq true
      expect(@class.primitive_is_clone? 'p_heat-engine').to eq false
      expect(@class.primitive_is_clone? 'p_rabbitmq-server').to eq false
      expect(@class.primitive_is_clone? 'UNKNOWN').to eq nil
    end

  end

  context 'cluster control' do
    it 'can enable maintenance mode' do
      @class.expects(:pcs).with 'property', 'set', 'maintenance-mode=true'
      @class.maintenance_mode 'true'
    end

    it 'can disable maintenance mode' do
      @class.expects(:pcs).with 'property', 'set', 'maintenance-mode=false'
      @class.maintenance_mode 'false'
    end

    it 'can set no-quorum policy' do
      @class.expects(:pcs).with 'property', 'set', 'no-quorum-policy=ignore'
      @class.no_quorum_policy 'ignore'
    end
  end

  context 'constraints control' do
    it 'can add location constraint' do
      @class.expects(:cibadmin).returns(true)
      @class.constraint_location_add 'myprimitive', 'mynode', '200'
    end

    it 'can remove location constraint' do
      @class.expects(:pcs).with 'constraint', 'location', 'remove', 'myprimitive_on_mynode'
      @class.constraint_location_remove 'myprimitive', 'mynode'
    end
  end

  context 'wait functions' do
    it 'retries block until it becomes true' do
      @class.retry_block_until_true { true }
    end

    it 'waits for Pacemaker to become ready' do
      @class.stubs(:is_online?).returns true
      @class.wait_for_online
    end

    it 'waits for status to become known' do
      @class.stubs(:cib_reset).returns true
      @class.stubs(:primitive_status).returns 'stopped'
      @class.wait_for_status 'myprimitive'
    end

    it 'waits for the service to start' do
      @class.stubs(:cib_reset).returns true
      @class.stubs(:primitive_is_running?).with('myprimitive', nil).returns true
      @class.wait_for_start 'myprimitive'
    end

    it 'waits for the service to stop' do
      @class.stubs(:cib_reset).returns true
      @class.stubs(:primitive_is_running?).with('myprimitive', nil).returns false
      @class.wait_for_stop 'myprimitive'
    end
  end

end
