require 'spec_helper'
require 'yaml'

describe Puppet::Parser::Functions.function(:get_network_role_to_ipaddr_map) do
let(:network_metadata) do
YAML.load("
---
  nodes:
    node-55:
      network_roles:
        nova/api: 192.168.1.55
        neutron/api: 192.168.3.55
      node_roles:
        - controller
        - mongo
        - cinder
    node-66:
      network_roles:
        nova/api: 192.168.1.66/24
        neutron/api: 192.168.3.66/25
      node_roles:
        - compute
        - cinder
        - xxx
        - yyy
    node-77:
      network_roles:
        nova/api: 192.168.1.77
        neutron/private: 192.168.3.77
      node_roles:
        - mongo
        - cinder
        - xxx
")
end
let(:nodes_hash) do
YAML.load("
---
  node-55:
    network_roles:
      nova/api: 192.168.1.5
      neutron/api: 192.168.3.5
  node-66:
    network_roles:
      nova/api: 192.168.1.6/24
      neutron/api: 192.168.3.6/25
  node-77:
    network_roles:
      nova/api: 192.168.1.7
      neutron/private: 192.168.3.7
")
end

  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  subject do
    function_name = Puppet::Parser::Functions.function(:get_network_role_to_ipaddr_map)
    scope.method(function_name)
  end

  context "get_network_role_to_ipaddr_map($nodes_hash, 'role') usage" do

    it 'should exist' do
      subject == Puppet::Parser::Functions.function(:get_network_role_to_ipaddr_map)
    end

    it 'should return nodes to IP map for "nova/api" role from network_metadata hash' do
      should run.with_params(network_metadata, 'nova/api').and_return({
        'node-55' => '192.168.1.55',
        'node-66' => '192.168.1.66',
        'node-77' => '192.168.1.77'
      })
    end

    it 'should return nodes to IP map for "nova/api" role from nodes_hash' do
      should run.with_params(nodes_hash, 'nova/api').and_return({
        'node-55' => '192.168.1.5',
        'node-66' => '192.168.1.6',
        'node-77' => '192.168.1.7'
      })
    end

    it 'should return nodes to IP map for "neutron/api" role from network_metadata hash' do
      should run.with_params(network_metadata, 'neutron/api').and_return({
        'node-55' => '192.168.3.55',
        'node-66' => '192.168.3.66'
      })
    end

    it 'should return nodes to IP map for "neutron/api" role from nodes_hash' do
      should run.with_params(nodes_hash, 'neutron/api').and_return({
        'node-55' => '192.168.3.5',
        'node-66' => '192.168.3.6'
      })
    end

    it 'should return {} if 1st argument has wrong format' do
      should run.with_params({:a=>1, :b=>2}, 'xxx/yyy').and_return({})
    end

    it 'should raise Puppet::ParseError if 1st argument not a Hash' do
      should run.with_params('xxx', 'yyy').and_raise_error(Puppet::ParseError)
    end

    it 'should raise Puppet::ParseError if 2nd argument not an string' do
      should run.with_params(network_metadata, ['cinder/api',]).and_raise_error(Puppet::ParseError)
    end

  end

end
