require 'spec_helper'
require 'yaml'


describe 'network_metadata_to_hosts' do

let(:network_metadata) {"""
---
  nodes:
    node-5:
      swift_zone: '5'
      uid: '5'
      fqdn: ctrl-005.domain.local
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
      name: ctrl-005
    node-4:
      swift_zone: '4'
      uid: '4'
      fqdn: ctrl-004.domain.local
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
      name: ctrl-004
    node-6:
      swift_zone: '6'
      uid: '6'
      fqdn: ctrl-006.domain.local
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
      name: ctrl-006
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
      'ctrl-006.domain.local' => {:ip => '10.88.0.8', :host_aliases => ['ctrl-006']},
      'ctrl-005.domain.local' => {:ip => '10.88.0.6', :host_aliases => ['ctrl-005']},
      'ctrl-004.domain.local' => {:ip => '10.88.0.7', :host_aliases => ['ctrl-004']},
    })
  end

  it 'should return hash for creating prefixed set of "host" puppet resources by create_resources()' do
    expect(scope.function_network_metadata_to_hosts([YAML.load(network_metadata), 'nova/migration', 'xxx-'])).to eq({
      'xxx-ctrl-006.domain.local' => {:ip => '10.77.0.8', :host_aliases => ['xxx-ctrl-006']},
      'xxx-ctrl-005.domain.local' => {:ip => '10.77.0.6', :host_aliases => ['xxx-ctrl-005']},
      'xxx-ctrl-004.domain.local' => {:ip => '10.77.0.7', :host_aliases => ['xxx-ctrl-004']},
    })
  end

  it { expect{scope.function_network_metadata_to_hosts([])}.to raise_error(ArgumentError, /Wrong number of arguments given/) }

  it 'should throw exception on wrong number of parameters' do
    expect{scope.function_network_metadata_to_hosts([YAML.load(network_metadata), 'nova/migration'])}.to \
      raise_error(ArgumentError, /opts are required/)
  end

end
