require 'spec_helper'
require 'yaml'


describe 'network_metadata_to_hosts' do

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
      name: custom-node-4
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
      name: node-6
  vips:
    vrouter_pub:
      network_role: public/vip
      node_roles:
      - controller
      - primary-controller
      namespace: vrouter
      ipaddr: 10.88.1.130
    management:
      network_role: mgmt/vip
      node_roles:
      - controller
      - primary-controller
      namespace: haproxy
      ipaddr: 10.88.0.10
    public:
      network_role: public/vip
      node_roles:
      - controller
      - primary-controller
      namespace: haproxy
      ipaddr: 10.88.1.131
    vrouter:
      network_role: mgmt/vip
      node_roles:
      - controller
      - primary-controller
      namespace: vrouter
      ipaddr: 10.88.0.9
"""}


  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  before(:each) do
    puppet_debug_override()
  end

  subject do
    function_name = Puppet::Parser::Functions.function('network_metadata_to_hosts')
    scope.method(function_name)
  end

  it 'should exist' do
    expect(subject).to eq scope.method('function_network_metadata_to_hosts')
  end

  it 'should return hash for creating ordinary set of "host" puppet resources by create_resources()' do
    expect(scope.function_network_metadata_to_hosts([YAML.load(network_metadata)])).to eq({
      'node-6.domain.local' => {:ip => '10.88.0.8', :host_aliases => ['node-6']},
      'node-5.domain.local' => {:ip => '10.88.0.6', :host_aliases => ['node-5']},
      'node-4.domain.local' => {:ip => '10.88.0.7', :host_aliases => ['custom-node-4']},
    })
  end

  it 'should return hash for creating prefixed set of "host" puppet resources by create_resources()' do
    expect(scope.function_network_metadata_to_hosts([YAML.load(network_metadata), 'nova/migration', 'xxx-'])).to eq({
      'xxx-node-6.domain.local' => {:ip => '10.77.0.8', :host_aliases => ['xxx-node-6']},
      'xxx-node-5.domain.local' => {:ip => '10.77.0.6', :host_aliases => ['xxx-node-5']},
      'xxx-node-4.domain.local' => {:ip => '10.77.0.7', :host_aliases => ['xxx-custom-node-4']},
    })
  end

  it 'should throw exception on wrong number of parameters' do
    expect{scope.function_network_metadata_to_hosts([YAML.load(network_metadata), 'nova/migration'])}.to \
      raise_error(Puppet::ParseError, /Wrong number of arg/)
  end

end
