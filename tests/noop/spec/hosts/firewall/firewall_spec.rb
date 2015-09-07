require 'spec_helper'
require 'shared-examples'
manifest = 'firewall/firewall.pp'

network_scheme = Noop.hiera('network_scheme', {})
keystone_network = '0.0.0.0/0'

describe manifest do
  shared_examples 'catalog' do

    let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

    before(:each) do
      scope.stubs(:lookupvar).with('l3_fqdn_hostname').returns('host.foo.com')
      Puppet::Parser::Functions.autoloader.load 'get_network_role_property'.to_sym
      Puppet::Parser::Functions.autoloader.load 'prepare_network_config'.to_sym
      scope.send 'function_prepare_network_config'.to_sym, [network_scheme]
      keystone_network = scope.send "function_get_network_role_property".to_sym, ['keystone/api', 'network']
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
  end

  test_ubuntu_and_centos manifest
end

