require 'spec_helper'
require 'yaml'
require 'puppetx/l23_hash_tools'

describe Puppet::Parser::Functions.function(:get_transformation_property) do
let(:network_scheme) do
<<eof
---
  version: 1.1
  provider: lnx
  interfaces:
    eth0:
      mtu: 2048
    eth1:
      mtu: 999
    eth2:
      mtu: 1024
    eth3: {}
  transformations:
    - action: add-br
      name: br-storage
    - action: add-br
      name: br-ex
    - action: add-br
      name: br-mgmt
    - action: add-port
      name: eth1.101
      bridge: br-mgmt
    - action: add-bond
      name: bond0
      bridge: br-storage
      interfaces:
        - eth2
        - eth3
      mtu: 4000
      bond_properties:
        mode: balance-rr
      interface_properties:
        mtu: 9000
        vendor_specific:
          disable_offloading: true
    - action: add-port
      name: bond0.102
      bridge: br-ex
    - action: add-br
      name: br-floating
      provider: ovs
    - action: add-patch
      bridges:
      - br-floating
      - br-ex
      provider: ovs
    - action: add-br
      name: br-prv
      provider: ovs
    - action: add-patch
      bridges:
      - br-prv
      - br-storage
      provider: ovs
  endpoints:
    eth0:
      IP:
        - '10.1.0.11/24'
    br-ex:
      gateway: 10.1.3.1
      IP:
        - '10.1.3.11/24'
    br-storage:
      IP:
        - '10.1.2.11/24'
    br-mgmt:
      IP:
        - '10.1.1.11/24'
    br-floating:
      IP: none
    br-prv:
      IP: none
  roles:
    admin: eth0
    ex: br-ex
    management: br-mgmt
    storage: br-storage
    neutron/floating: br-floating
    neutron/private: br-prv
eof
end



  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  subject do
    function_name = Puppet::Parser::Functions.function(:get_transformation_property)
    scope.method(function_name)
  end

  context "get_transformation_property('some_property', 'transformation') usage" do
    before(:each) do
      scope.stubs(:lookupvar).with('l3_fqdn_hostname').returns('node1.tld')
      L23network::Scheme.set_config(
        scope.lookupvar('l3_fqdn_hostname'),
        L23network.sanitize_keys_in_hash(YAML.load(network_scheme))
      )
    end

    it 'should exist' do
      subject == Puppet::Parser::Functions.function(:get_transformation_property)
    end

    it 'should return mtu value for "bond0" transformation' do
      should run.with_params('mtu', 'bond0').and_return(4000)
    end

    it 'should return mtu value for "eth0" transformation' do
      should run.with_params('mtu', 'eth0').and_return(2048)
    end

    it 'should return 1024 for "eth2" transformation' do
      should run.with_params('mtu', 'eth2').and_return(1024)
    end

    it 'should return NIL for "eth3" transformation' do
      should run.with_params('mtu', 'eth3').and_return(nil)
    end

    it 'should return ovs for "br-floating" transformation' do
      should run.with_params('provider', 'br-floating').and_return('ovs')
    end

    it 'should return NIL for "br-storage" transformation' do
      should run.with_params('provider', 'br-storage').and_return(nil)
    end

  end

end
