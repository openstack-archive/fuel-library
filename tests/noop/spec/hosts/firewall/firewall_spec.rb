require 'spec_helper'
require 'shared-examples'
manifest = 'firewall/firewall.pp'

keystone_network = '0.0.0.0/0'

describe manifest do
  shared_examples 'catalog' do

    let(:network_scheme) do
      Noop.hiera_hash 'network_scheme', {}
    end

    let(:prepare) do
      Noop.puppet_function 'prepare_network_config', network_scheme
    end

    let(:keystone_network) do
      prepare
      Noop.puppet_function 'get_network_role_property', 'keystone/api', 'network'
    end

    let(:nova_vnc_ip_range) do
      prepare
      Noop.puppet_function 'get_routable_networks_for_network_role', network_scheme, 'nova/api'
    end

    it 'should properly restrict rabbitmq admin traffic' do

      should contain_firewall('005 local rabbitmq admin').with(
        'sport'   => [ 15672 ],
        'iniface' => 'lo',
        'proto'   => 'tcp',
        'action'  => 'accept'
      )
      should contain_firewall('006 reject non-local rabbitmq admin').with(
        'sport'   => [ 15672 ],
        'proto'   => 'tcp',
        'action'  => 'drop'
      )
    end

    it 'should accept connections to keystone API using network with keystone/api role' do
      should contain_firewall('102 keystone').with(
        'port'       => [ 5000, 35357 ],
        'proto'       => 'tcp',
        'action'      => 'accept',
        'destination' => keystone_network,
      )
    end

    it 'should accept connections to vnc' do
      nova_vnc_ip_range.each do |source|
        should contain_firewall("120 vnc ports for #{source}").with(
          'port'   => '5900-6100',
          'proto'  => 'tcp',
          'source' => source,
          'action' => 'accept',
        )
      end
    end

    it 'should create rules for heat' do
      should contain_firewall('204 heat-api').with(
        'port'    => [ 8004 ],
        'proto'   => 'tcp',
        'action'  => 'accept',
      )
      should contain_firewall('205 heat-api-cfn').with(
        'port'    => [ 8000 ],
        'proto'   => 'tcp',
        'action'  => 'accept',
      )
      should contain_firewall('206 heat-api-cloudwatch').with(
        'port'    => [ 8003 ],
        'proto'   => 'tcp',
        'action'  => 'accept',
      )
    end
  end

  test_ubuntu_and_centos manifest
end

