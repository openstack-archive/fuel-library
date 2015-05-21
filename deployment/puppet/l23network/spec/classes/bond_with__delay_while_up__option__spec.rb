require 'spec_helper'

describe 'l23network::examples::run_network_scheme', :type => :class do
let(:network_scheme) do
<<eof
---
network_scheme:
  version: 1.1
  provider: lnx
  interfaces:
    eth1: {}
    eth2: {}
    eth3: {}
    eth4: {}
    eth5: {}
    eth6: {}
    eth7: {}
    eth8: {}
    eth9: {}
    eth10: {}
    eth11: {}
    eth12: {}
  transformations:
    - action: add-bond
      name: bond0
      interfaces:
        - eth1
        - eth2
      bond_properties:
        mode: 802.3ad
    - action: add-bond
      name: bond1
      interfaces:
        - eth3
        - eth4
      bond_properties:
        mode: 802.3ad
      delay_while_up: 77
    - action: add-bond
      name: bond2
      interfaces:
        - eth5
        - eth6
      bond_properties:
        mode: balance-rr
    - action: add-bond
      name: bond3
      interfaces:
        - eth7
        - eth8
      bond_properties:
        mode: balance-rr
      delay_while_up: 77
    - action: add-br
      name: br910
    - action: add-bond
      name: bond910
      bridge: br910
      interfaces:
        - eth9
        - eth10
      bond_properties:
        mode: balance-rr
    - action: add-br
      name: br911
      delay_while_up: 77
    - action: add-bond
      name: bond911
      bridge: br911
      interfaces:
        - eth11
        - eth12
      bond_properties:
        mode: balance-rr
  endpoints: {}
  roles: {}
eof
end

  context '"delay_while_up" property for' do
    let(:title) { 'lacp_bonds' }
    let(:facts) {
      {
        :osfamily => 'RedHat',
        :operatingsystem => 'Centos',
        :kernel => 'Linux',
        :l23_os => 'centos6',
        :l3_fqdn_hostname => 'stupid_hostname',
      }
    }

    let(:params) do {
      :settings_yaml => network_scheme,
    } end

    it do
      should compile
    end

    it 'LACP bond without defined delay' do
      should contain_l23_stored_config('bond0').with({
        'delay_while_up'  => '45',
      })
    end

    it 'LACP bond with specified delay' do
      should contain_l23_stored_config('bond1').with({
        'delay_while_up'  => '77',
      })
    end

    it 'non LACP bond without defined delay' do
      should contain_l23_stored_config('bond2').with({
        'delay_while_up'  => '15',
      })
    end

    it 'non LACP bond with specified delay' do
      should contain_l23_stored_config('bond3').with({
        'delay_while_up'  => '77',
      })
    end

  end

  context '"delay_while_up" property for bond, included to bridge ' do
    let(:title) { 'lacp_bonds' }
    let(:facts) {
      {
        :osfamily => 'RedHat',
        :operatingsystem => 'Centos',
        :kernel => 'Linux',
        :l23_os => 'centos6',
        :l3_fqdn_hostname => 'stupid_hostname',
      }
    }

    let(:params) do {
      :settings_yaml => network_scheme,
    } end

    it 'bond should assembled without delay' do
      should contain_l23_stored_config('bond910').with({
        'delay_while_up' => nil,
        'bridge' => 'br910'
      })
    end

    it 'bridge should contain delay from bond' do
      should contain_l23_stored_config('br910').with({
        'delay_while_up'  => '15',
      })
    end

    it "bridge's delay_while_up has more priority, than bond's" do
      should contain_l23_stored_config('br911').with({
        'delay_while_up'  => '77',
      })
    end


  end

end

###
