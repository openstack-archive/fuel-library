require 'spec_helper'
require 'shared-examples'
manifest = 'firewall/firewall_baremetal.pp'

describe manifest do
  shared_examples 'catalog' do

    if Noop.hiera_structure 'ironic/enabled'
      let(:network_scheme) do
        Noop.hiera_hash 'network_scheme', {}
      end

      let(:prepare) do
        Noop.puppet_function 'prepare_network_config', network_scheme
      end

      let(:baremetal_network) do
        Noop.puppet_function 'get_network_role_property', 'ironic/baremetal', 'network'
      end

      let(:baremetal_ipaddr) do
        Noop.puppet_function 'get_network_role_property', 'ironic/baremetal', 'ipaddr'
      end

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

  end

  test_ubuntu_and_centos manifest
end

