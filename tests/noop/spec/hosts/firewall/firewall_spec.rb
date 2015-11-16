require 'spec_helper'
require 'shared-examples'
manifest = 'firewall/firewall.pp'

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

    let(:private_nets) do
      prepare
      Noop.puppet_function 'get_routable_networks_for_network_role', network_scheme, 'management'
    done
    let(:storage_nets) do
      prepare
      Noop.puppet_function 'get_routable_networks_for_network_role', network_scheme, 'storage'
    done

    let(:baremetal_network) do
      Noop.puppet_function 'get_network_role_property', 'ironic/baremetal', 'network'
    end

    let(:baremetal_ipaddr) do
      Noop.puppet_function 'get_network_role_property', 'ironic/baremetal', 'ipaddr'
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
        'port'        => [ 5000, 35357 ],
        'proto'       => 'tcp',
        'action'      => 'accept',
        'destination' => keystone_network,
      )
    end

    it 'should accept connections to nova' do
      should contain_firewall('105 nova').with(
        'port'        => [ 8774, 8776, 6080 ],
        'proto'       => 'tcp',
        'action'      => 'accept',
      )
    end

    it 'should accept connections to nova without ssl' do
      private_nets.each do |source|
        should contain_firewall("105 nova private - no ssl from #{source}").with(
          'port'        => [ 8775, '5900-6100' ],
          'proto'       => 'tcp',
          'action'      => 'accept',
          'source'      => source,
        )
      end
    end

    it 'should accept connections to iscsi' do
      storage_nets.each do |source|
        should contain_firewall("109 iscsi from #{source}").with(
          'port'        => [ 3260 ],
          'proto'       => 'tcp',
          'action'      => 'accept',
          'source'      => source,
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

    if Noop.hiera_structure 'ironic/enabled'
      if Noop.hiera('node_role') == 'controller' or Noop.hiera('node_role') == 'primary-controller'
        it 'should drop all traffic from baremetal network' do
          should contain_firewall('999 drop all baremetal').with(
            'chain'  => 'baremetal',
            'proto'  => 'all',
            'action' => 'drop',
          )
        end
        it 'should enable 6385 ironic-api port' do
            should contain_firewall('207 ironic-api').with(
              'dport'   => '6385',
              'proto'   => 'tcp',
              'action'  => 'accept'
            )
        end
      end

      if Noop.hiera('node_role') == 'ironic'
        it 'should create rules for ironic on conductor' do
          should contain_firewall('102 allow baremetal-rsyslog').with(
            'chain'       => 'baremetal',
            'dport'       => [ 514 ],
            'proto'       => 'udp',
            'action'      => 'accept',
            'source'      => baremetal_network,
            'destination' => baremetal_ipaddr,
          )
          should contain_firewall('103 allow baremetal-TFTP').with(
            'chain'       => 'baremetal',
            'dport'       => [ 69 ],
            'proto'       => 'udp',
            'action'      => 'accept',
            'source'      => baremetal_network,
            'destination' => baremetal_ipaddr,
          )
        end
      end
    end

    it 'should accept connections from 240.0.0.2' do
      should contain_firewall('030 allow connections from haproxy namespace').with(
        'source'      => '240.0.0.2',
        'action'      => 'accept',
      )
    end

  end

  test_ubuntu_and_centos manifest
end

