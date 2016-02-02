require 'spec_helper'
require 'yaml'
require 'puppetx/l23_hash_tools'

describe Puppet::Parser::Functions.function(:get_nic_passthrough_whitelist) do
let(:network_scheme) do
<<eof
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



  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  subject do
    function_name = Puppet::Parser::Functions.function(:get_nic_passthrough_whitelist)
    scope.method(function_name)
  end

  context "get_nic_passthrough_whitelist() usage" do
    before(:each) do
      scope.stubs(:lookupvar).with('l3_fqdn_hostname').returns('node1.tld')
      L23network::Scheme.set_config(
        scope.lookupvar('l3_fqdn_hostname'),
        L23network.sanitize_keys_in_hash(YAML.load(network_scheme))
      )
    end

    it 'should exist' do
      subject == Puppet::Parser::Functions.function(:get_pci_passthrough_whitelist)
    end

    it 'should return sriov mappings from transformations' do
      should run.with_params('sriov').and_return([
        {"devname" => "enp1s0f0", "physical_network" => "physnet1"},
        {"devname" => "enp1s0f1", "physical_network" => "physnet2"}
       ])
    end

    it 'should return empty mapping from transformations' do
      should run.with_params('dumb').and_return(nil)
    end
  end

end