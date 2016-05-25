require 'spec_helper'
require 'yaml'

describe 'the roles_include function' do

let(:network_metadata) {"""
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
"""}

  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  before(:each) do
    puppet_debug_override()
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
    expect(
        Puppet::Parser::Functions.function('roles_include')
    ).to eq('function_roles_include')
  end

  it 'should raise an error if there is less than 1 arguments' do
    expect {
      scope.function_roles_include([])
    }.to raise_error /Wrong number of arguments/
  end


  it 'should be able to find a matching role' do
    expect(
        scope.function_roles_include [ 'controller' ]
    ).to eq true
    expect(
        scope.function_roles_include [ %w(controller primary-controller) ]
    ).to eq true
  end

  it 'should be able to find a non-matching role' do
    expect(
        scope.function_roles_include [ 'compute' ]
    ).to eq false
    expect(
        scope.function_roles_include [ %w(compute cinder) ]
    ).to eq false
  end

end
