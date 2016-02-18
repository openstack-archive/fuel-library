require 'spec_helper'
require 'yaml'
require 'puppetx/l23_hash_tools'

describe Puppet::Parser::Functions.function(:get_dpdk_interfaces) do
let(:network_scheme) do
<<eof
---
  version: 1.1
  provider: lnx
  interfaces:
    enp2s0f0:
      vendor_specific:
        driver: tg3
        bus_info: "0000:02:00.0"
    enp1s0f1:
      vendor_specific:
        driver: ixgbe
        bus_info: "0000:01:00.1"
    enp1s0f0:
      vendor_specific:
        driver: ixgbe
        bus_info: "0000:01:00.0"
    eno1:
      vendor_specific:
        driver: tg3
        bus_info: "0000:02:00.1"
  transformations:
    - bridge: br-prv
      name: enp1s0f0
      action: add-port
      provider: dpdkovs
      vendor_specific:
        dpdk_driver: igb_uio
eof
end

  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  subject do
    function_name = Puppet::Parser::Functions.function(:get_dpdk_interfaces)
    scope.method(function_name)
  end

  context "get_dpdk_interfaces() usage" do
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

    it 'should return dpdk driver list' do
      should run.with_params().and_return([["0000:01:00.0", "igb_uio"]])
    end
  end
end
