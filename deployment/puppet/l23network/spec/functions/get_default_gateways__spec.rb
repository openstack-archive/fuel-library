require 'spec_helper'
require 'yaml'
require_relative '../../lib/puppetx/l23_hash_tools'

describe 'get_default_gateways' do

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
  endpoints:
    eth0:
      IP: 'none'
    eth4:
      IP: 'none'
    br-ex:
      gateway: 10.1.3.1
      IP:
        - '10.1.3.11/24'
    br-mgmt:
      gateway: 10.1.1.1
      gateway_metric: 20
      IP:
        - '10.1.1.11/24'
    br-storage:
      gateway: 10.1.2.1
      gateway_metric: 10
      IP:
        - '10.1.2.11/24'
    br-floating:
      IP: none
eof
  end

  it 'should exist' do
    is_expected.not_to be_nil
  end

  context ":get_default_gateways() usage" do
    before(:each) do
      scope.stubs(:lookupvar).with('l3_fqdn_hostname').returns('node1.tld')
      L23network::Scheme.set_config(
        scope.lookupvar('l3_fqdn_hostname'),
        L23network.sanitize_keys_in_hash(YAML.load(network_scheme))
      )
    end

    it do
      is_expected.to run.with_params().and_return(['10.1.3.1', '10.1.2.1', '10.1.1.1'])
    end

  end

end
