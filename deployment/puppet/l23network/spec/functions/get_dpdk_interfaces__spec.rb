require 'spec_helper'
require 'yaml'
require_relative '../../lib/puppetx/l23_hash_tools'

describe 'get_dpdk_interfaces' do

  let(:network_scheme) do
    <<-eof
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
        dpdk_driver: igb_uio
    enp1s0f0:
      vendor_specific:
        driver: ixgbe
        bus_info: "0000:01:00.0"
        dpdk_driver: igb_uio
    eno1:
      vendor_specific:
        driver: tg3
        bus_info: "0000:02:00.1"
    eof
  end

  it 'should exist' do
    is_expected.not_to be_nil
  end

  context "get_dpdk_interfaces() usage" do
    before(:each) do
      scope.stubs(:lookupvar).with('l3_fqdn_hostname').returns('node1.tld')
      L23network::Scheme.set_config(
          scope.lookupvar('l3_fqdn_hostname'),
          L23network.sanitize_keys_in_hash(YAML.load(network_scheme))
      )
    end

    it 'should return dpdk driver list' do
      is_expected.to run.with_params().and_return(
          [
              ["0000:01:00.0", "igb_uio"], ["0000:01:00.1", "igb_uio"]
          ]
      )
    end
  end
end
