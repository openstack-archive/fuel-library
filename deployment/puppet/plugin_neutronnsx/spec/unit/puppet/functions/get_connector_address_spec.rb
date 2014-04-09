require 'spec_helper'

describe Puppet::Parser::Functions.function(:get_connector_address) do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }
  describe "when calling from puppet" do
    it "should not compile without parameters" do
      Puppet[:code] = 'get_connector_address()'
      expect {
        scope.compiler.compile
      }.to raise_error(Puppet::ParseError,/Wrong number of arguments/)
    end
  end
  describe "when calling on the scope instance" do
    let :fuel_settings do
      {
      'fqdn' => 'node-42.domain.tld',
      'nodes' => [ {
          'storage_netmask' => '255.255.255.0',
          'uid' => '41',
          'public_address' => '172.18.198.140',
          'internal_netmask' => '255.255.255.0',
          'fqdn' => 'node-41.domain.tld',
          'role' => 'controller',
          'public_netmask' => '255.255.255.224',
          'internal_address' => '192.168.0.2',
          'storage_address' => '192.168.1.2',
          'name' => 'node-41',
          },{
          'storage_netmask' => '255.255.255.0',
          'uid' => '42',
          'public_address' => '172.18.198.141',
          'internal_netmask' => '255.255.255.0',
          'fqdn' => 'node-42.domain.tld',
          'role' => 'compute',
          'public_netmask' => '255.255.255.224',
          'internal_address' => '192.168.0.3',
          'storage_address' => '192.168.1.3',
          'name' => 'node-42',
          }
        ]
      }
    end
    it "should return connector addres" do
      fuel_settings['nsx_plugin'] = {'nsx_controllers' => '192.168.0.100,192.168.0.101'}
      connector_addr = scope.function_get_connector_address([fuel_settings])
      connector_addr.should == '192.168.0.3'
    end
    it "should return pubblc for non-Fuel networks" do
      fuel_settings['nsx_plugin'] = {'nsx_controllers' => '10.20.0.1,10.20.0.2'}
      scope.function_get_connector_address([fuel_settings]).should == '172.18.198.141'
    end
    it "should raise if fqdn not found" do
      fuel_settings['nsx_plugin'] = {'nsx_controllers' => '192.168.0.100,192.168.0.101'}
      fuel_settings['fqdn'] = 'node-1.domain.tld'
      expect {
        scope.function_get_connector_address([fuel_settings])
      }.to raise_error(Puppet::ParseError, /not found/)
    end
  end
end
