require 'spec_helper'
require 'yaml'
require_relative '../../lib/puppetx/l23_hash_tools'

describe 'get_network_role_property' do

  let(:network_scheme) do
    <<-eof
---
  version: 1.1
  provider: lnx
  interfaces:
    eth0:
      mtu: 2048
    eth1:
      mtu: 999
    eth2: {}
    eth3: {}
    eth4: {}
    eth5: {}
    eth44: {}
  transformations:
    - action: add-br
      name: br-aux
    - action: add-port
      name: eth5.105
      bridge: br-aux
    - action: add-port
      name: bond0.110
      bridge: br-aux
    - action: add-br
      name: br-storage
    - action: add-br
      name: br-ex
    - action: add-br
      name: br-mgmt
    - action: add-port
      name: eth4
      mtu: 777
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
    - action: add-port
      name: bond0.103
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
    - action: add-br
      name: br44
    - action: add-port
      name: eth44
      bridge: br44
  endpoints:
    eth0:
      IP: 'none'
    eth4:
      IP: 'none'
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
    br-aux:
      IP: none
    br44:
      IP: none
    bond0.103:
      IP: none
  roles:
    admin: eth0
    ex: br-ex
    management: br-mgmt
    storage: br-storage
    neutron/floating: br-floating
    neutron/private: br-prv
    xxx: eth4
    custom: br-aux
    zzz: br44
    bond_103: bond0.103
    eof
  end

  it 'should exist' do
    is_expected.not_to be_nil
  end

  context "get_network_role_property('**something_role**', 'phys_dev') usage" do
    before(:each) do
      scope.stubs(:lookupvar).with('l3_fqdn_hostname').returns('node1.tld')
      L23network::Scheme.set_config(
          scope.lookupvar('l3_fqdn_hostname'),
          L23network.sanitize_keys_in_hash(YAML.load(network_scheme))
      )
    end

    it 'should return physical device name for "management" network role (just subinterface)' do
      is_expected.to run.with_params('management', 'phys_dev').and_return(["eth1"])
    end

    it 'should return physical device name for "ex" network role (subinterface of bond)' do
      is_expected.to run.with_params('ex', 'phys_dev').and_return(["bond0", "eth2", "eth3"])
    end

    it 'should return physical device name for "floating" network role (OVS-bridge, connected by patch to LNX bridge)' do
      is_expected.to run.with_params('neutron/floating', 'phys_dev').and_return(["bond0", "eth2", "eth3"])
    end

    it 'should return physical device name for "private" network role' do
      is_expected.to run.with_params('neutron/private', 'phys_dev').and_return(["bond0", "eth2", "eth3"])
    end

    it 'should return physical device name for "storage" network role (bond, without tag)' do
      is_expected.to run.with_params('storage', 'phys_dev').and_return(["bond0", "eth2", "eth3"])
    end

    it 'should return physical device name for "admin" network role (just interface has IP address)' do
      is_expected.to run.with_params('admin', 'phys_dev').and_return(['eth0'])
    end

    it 'should return physical device name for untagged interface with simple transformation' do
      is_expected.to run.with_params('xxx', 'phys_dev').and_return(['eth4'])
    end

    it 'should return physical device name for subinterface of bond' do
      is_expected.to run.with_params('bond_103', 'phys_dev').and_return(["bond0", "eth2", "eth3"])
    end

    it 'should return physical devices names for "custom" network role (two interfaces)' do
      is_expected.to run.with_params('custom', 'phys_dev').and_return(["eth5", "bond0"])
    end

    it 'should return physical device name for endpoint with interface with long name, contains shot name of another interface' do
      is_expected.to run.with_params('zzz', 'phys_dev').and_return(['eth44'])
    end

    it 'should return NIL for "non-existent" network role' do
      is_expected.to run.with_params('non-existent', 'phys_dev').and_return(nil)
    end
  end

end
