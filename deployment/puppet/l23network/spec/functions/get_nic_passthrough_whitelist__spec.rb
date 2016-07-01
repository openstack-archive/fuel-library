require 'spec_helper'
require 'yaml'
require_relative '../../lib/puppetx/l23_hash_tools'

describe 'get_nic_passthrough_whitelist' do

  let(:network_scheme) do
    <<-eof
---
  version: 1.1
  provider: lnx
  interfaces:
    enp1s0f0:
      mtu: 1500
    enp1s0f1:
      mtu: 1500
  transformations:
    - action: add-port
      name: enp1s0f0
      provider: sriov
      vendor_specific:
        sriov_numvfs: 63
        physnet: physnet1
    - action: add-port
      name: enp1s0f1
      provider: sriov
      vendor_specific:
        sriov_numvfs: 63
        physnet: physnet2
    - action: add-port
      name: eth0
      provider: sriov
      vendor_specific:
        sriov_numvfs: 4
  endpoints:
  roles:
    eof
  end

  it 'should exist' do
    is_expected.not_to be_nil
  end

  context "get_nic_passthrough_whitelist() usage" do
    before(:each) do
      scope.stubs(:lookupvar).with('l3_fqdn_hostname').returns('node1.tld')
      L23network::Scheme.set_config(
          scope.lookupvar('l3_fqdn_hostname'),
          L23network.sanitize_keys_in_hash(YAML.load(network_scheme))
      )
    end

    it 'should return sriov mappings from transformations' do
      is_expected.to run.with_params('sriov').and_return(
          [
              {"devname" => "enp1s0f0", "physical_network" => "physnet1"},
              {"devname" => "enp1s0f1", "physical_network" => "physnet2"}
          ]
      )
    end

    it 'should return empty mapping from transformations' do
      is_expected.to run.with_params('dumb').and_return(nil)
    end
  end

end
