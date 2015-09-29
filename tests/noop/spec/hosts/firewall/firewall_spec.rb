require 'spec_helper'
require 'shared-examples'
manifest = 'firewall/firewall.pp'

network_scheme = Noop.hiera('network_scheme', {})
keystone_network = '0.0.0.0/0'
baremetal_network = '1.1.1.0/24'
baremetal_ipaddr  = '1.1.1.1'

describe manifest do
  shared_examples 'catalog' do

    let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

    before(:each) do
      scope.stubs(:lookupvar).with('l3_fqdn_hostname').returns('host.foo.com')
      Puppet::Parser::Functions.autoloader.load 'get_network_role_property'.to_sym
      Puppet::Parser::Functions.autoloader.load 'prepare_network_config'.to_sym
      scope.send 'function_prepare_network_config'.to_sym, [network_scheme]
      keystone_network = scope.send "function_get_network_role_property".to_sym, ['keystone/api', 'network']
      if Noop.hiera_structure 'ironic/enabled'
        baremetal_network = scope.send "function_get_network_role_property".to_sym, ['ironic/baremetal', 'network']
        baremetal_ipaddr  = scope.send "function_get_network_role_property".to_sym, ['ironic/baremetal', 'ipaddr']
      end
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

  end

  test_ubuntu_and_centos manifest
end

