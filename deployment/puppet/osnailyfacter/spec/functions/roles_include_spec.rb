require 'spec_helper'
require 'yaml'

describe 'roles_include' do

  let(:network_metadata) do
    <<-eof
---
  nodes:
    node-5:
      swift_zone: '5'
      uid: '5'
      fqdn: node-5.domain.local
      network_roles:
        keystone/api: 10.88.0.6
        neutron/api: 10.88.0.6
        mgmt/database: 10.88.0.6
        mgmt/vip: 10.88.0.6
        sahara/api: 10.88.0.6
        nova/migration: 10.77.0.6
      user_node_name: CO22
      node_roles:
      - compute
      - cinder
      name: node-5
    node-4:
      swift_zone: '4'
      uid: '4'
      fqdn: node-4.domain.local
      network_roles:
        keystone/api: 10.88.0.7
        neutron/api: 10.88.0.7
        mgmt/database: 10.88.0.7
        mgmt/vip: 10.88.0.7
        sahara/api: 10.88.0.7
        heat/api: 10.88.0.7
        ceilometer/api: 10.88.0.7
        nova/migration: 10.77.0.7
        ex: 10.88.1.132
      user_node_name: CNT21
      node_roles:
      - primary-controller
      - controller
      name: node-4
    node-6:
      swift_zone: '6'
      uid: '6'
      fqdn: node-6.domain.local
      network_roles:
        keystone/api: 10.88.0.8
        neutron/api: 10.88.0.8
        mgmt/database: 10.88.0.8
        sahara/api: 10.88.0.8
        ceilometer/api: 10.88.0.8
        mgmt/vip: 10.88.0.8
        nova/migration: 10.77.0.8
      user_node_name: CO23
      node_roles:
      - compute
      - cinder
      name: node-6
    eof
  end

  before(:each) do
    puppet_debug_override
  end

  before(:each) do
    scope.stubs(:function_hiera_hash).with(['network_metadata']).returns(YAML.load(network_metadata))
    scope.stubs(:call_function).with('hiera_hash', 'network_metadata').returns(YAML.load(network_metadata))
  end

  before(:each) do
    scope.stubs(:function_get_node_key_name).with([]).returns('node-4')
    scope.stubs(:call_function).with('get_node_key_name').returns('node-4')
  end

  it 'should exist' do
    is_expected.not_to be_nil
  end

  it { is_expected.to run.with_params().and_raise_error(ArgumentError) }

  it { is_expected.to run.with_params('controller').and_return(true) }

  it { is_expected.to run.with_params(%w(controller primary-controller)).and_return(true) }

  it { is_expected.to run.with_params('compute').and_return(false) }

  it { is_expected.to run.with_params(%w(compute cinder)).and_return(false) }

end
