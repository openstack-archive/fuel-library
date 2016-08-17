require 'spec_helper'

describe 'l23network::examples::run_network_scheme', :type => :class do
let(:network_scheme) do
<<eof
---
network_scheme:
  version: 1.1
  provider: lnx
  interfaces:
    eth2: {}
    eth3: {}
  transformations:
    - action: add-bond
      name: bond23
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
  endpoints: {}
  roles: {}
eof
end

  context 'with bond (lnx) two interfaces' do
    let(:title) { 'empty network scheme' }
    let(:facts) {
      {
        :osfamily => 'Debian',
        :operatingsystem => 'Ubuntu',
        :kernel => 'Linux',
        :l23_os => 'ubuntu',
        :l3_fqdn_hostname => 'stupid_hostname',
        :netrings => {
          'eth1' => {
            'maximums' => {'rx'=>'4096', 'tx'=>'4096'},
            'current' => {'rx'=>'256', 'tx'=>'256'}
          },
          'eth2' => {
            'maximums' => {'rx'=>'4096', 'tx'=>'4096'},
            'current' => {'rx'=>'256', 'tx'=>'256'}
          },
          'eth3' => {
            'maximums' => {'rx'=>'4096', 'tx'=>'4096'},
            'current' => {'rx'=>'2048', 'tx'=>'2048'}
          }
        }
      }
    }

    let(:params) do {
      :settings_yaml => network_scheme,
    } end

    before(:each) do
      puppet_debug_override()
    end

    it do
      should compile.with_all_deps
    end

    it do
      should contain_l2_bond('bond23').with({
        'ensure' => 'present',
        'slaves' => ['eth2', 'eth3'],
        'mtu'    => 4000,
      })
    end

    ['eth2', 'eth3'].each do |iface|
      it do
        should contain_l2_port(iface).with({
          'ensure'  => 'present',
          'mtu'     => 9000,
          'bond_master'  => 'bond23',
          'ethtool' =>  {
              'offload' => {
                'generic-receive-offload'      => false,
                'generic-segmentation-offload' => false
              }
          }.merge!({'rings' => facts[:netrings][iface]['maximums']})
        })
      end
    end
    ['eth2', 'eth3'].each do |iface|
      it do
        should contain_l23_stored_config(iface).with({
          'ensure'  => 'present',
          'mtu'     => 9000,
          'bond_master'  => 'bond23',
          'ethtool' =>  {
              'offload' => {
                'generic-receive-offload'      => false,
                'generic-segmentation-offload' => false
              }
          }.merge({'rings' => facts[:netrings][iface]['maximums']})
        })
      end
    end

  end

end

describe 'l23network::examples::run_network_scheme', :type => :class do
let(:network_scheme) do
<<eof
---
network_scheme:
  version: 1.1
  provider: lnx
  interfaces:
    eth2: {}
    eth3: {}
  transformations:
    - action: add-bond
      name: bond23
      interfaces:
        - eth2
        - eth3
      bridge: some-bridge
      mtu: 4000
      bond_properties:
        mode: balance-rr
      interface_properties:
        mtu: 9000
        vendor_specific:
          disable_offloading: true
      provider: ovs
  endpoints: {}
  roles: {}
eof
end

  context 'with bond (ovs) two interfaces' do
    let(:title) { 'empty network scheme' }
    let(:facts) {
      {
        :osfamily => 'Debian',
        :operatingsystem => 'Ubuntu',
        :kernel => 'Linux',
        :l23_os => 'ubuntu',
        :l3_fqdn_hostname => 'stupid_hostname',
        :netrings => {}
      }
    }

    let(:params) do {
      :settings_yaml => network_scheme,
    } end

    before(:each) do
      puppet_debug_override()
    end

    it do
      should compile.with_all_deps
    end

    it do
      should contain_l2_bond('bond23').with({
        'ensure'   => 'present',
        'provider' => 'ovs',
        'slaves'   => ['eth2', 'eth3'],
        'mtu'      => 4000,
      })
    end

    ['eth2', 'eth3'].each do |iface|
      it do
        should contain_l2_port(iface).with({
          'ensure'      => 'present',
          'mtu'         => 9000,
          'bond_master' => nil,
          'ethtool' =>  {
              'offload' => {
                'generic-receive-offload'      => false,
                'generic-segmentation-offload' => false
              }
            }
        })
        should contain_l23_stored_config(iface).with({
          'ensure'      => 'present',
          'mtu'         => 9000,
          'bond_master' => nil,
          'ethtool' =>  {
              'offload' => {
                'generic-receive-offload'      => false,
                'generic-segmentation-offload' => false
              }
            }
        })
      end
    end

  end

end

###
