require 'spec_helper'

describe 'l23network::examples::run_network_scheme', :type => :class do
let(:network_scheme) do
<<eof
---
network_scheme:
  version: 1.1
  provider: lnx
  interfaces:
    eth0:
      ethtool:
       offload:
        generic-receive-offload: true
        generic-segmentation-offload: true
        rx-all: true
        rx-checksumming: true
        rx-fcs: true
        rx-vlan-offload: true
        scatter-gather: true
        tcp-segmentation-offload: true
        tx-checksumming: true
        tx-nocache-copy: true
    eth1:
      vendor_specific:
        disable_offloading: true
    eth2: {}
    eth3: {}
  transformations:
    - action: add-br
      name: br-eth0
    - action: add-port
      bridge: br-eth0
      name: eth0
    - action: add-br
      name: br-eth1
    - action: add-port
      bridge: br-eth1
      name: eth1
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
  emdpoints: {}
  roles: {}
eof
end

  context 'ethtool for interfaces' do
    let(:title) { 'empty network scheme' }
    let(:facts) {
      {
        :osfamily => 'Debian',
        :operatingsystem => 'Ubuntu',
        :kernel => 'Linux',
        :l23_os => 'ubuntu',
        :l3_fqdn_hostname => 'stupid_hostname',
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
      should contain_l2_bridge('br-eth0').with({
      })
    end

    it do
      should contain_l23_stored_config('eth0').with({
         'ensure'  => 'present',
         'bridge'  => 'br-eth0',
         'ethtool' =>  {
              'offload' => {
                'generic-receive-offload'      => true,
                'generic-segmentation-offload' => true,
                'rx-all'                       => true,
                'rx-checksumming'              => true,
                'rx-fcs'                       => true,
                'rx-vlan-offload'              => true,
                'scatter-gather'               => true,
                'tcp-segmentation-offload'     => true,
                'tx-checksumming'              => true,
                'tx-nocache-copy'              => true
              }}
      })
    end

    it do
      should contain_l2_port('eth0').with({
        'bridge' => 'br-eth0',
        'ethtool' =>  {
              'offload' => {
                'generic-receive-offload'      => true,
                'generic-segmentation-offload' => true,
                'rx-all'                       => true,
                'rx-checksumming'              => true,
                'rx-fcs'                       => true,
                'rx-vlan-offload'              => true,
                'scatter-gather'               => true,
                'tcp-segmentation-offload'     => true,
                'tx-checksumming'              => true,
                'tx-nocache-copy'              => true
              }}
      })
    end

    it do
      should contain_l2_bridge('br-eth1').with({
      })
    end

    it do
      should contain_l23_stored_config('eth1').with({
         'ensure'  => 'present',
         'bridge'  => 'br-eth1',
         'ethtool' =>  {
              'offload' => {
                'generic-receive-offload'      => false,
                'generic-segmentation-offload' => false
              }}
      })
    end

    it do
      should contain_l2_port('eth1').with({
        'bridge' => 'br-eth1',
        'ethtool' =>  {
              'offload' => {
                'generic-receive-offload'      => false,
                'generic-segmentation-offload' => false
              }
        }})
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
            }
        })
        should contain_l23_stored_config(iface).with({
          'ensure'  => 'present',
          'mtu'     => 9000,
          'bond_master'  => 'bond23',
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

