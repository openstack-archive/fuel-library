require 'spec_helper'

describe 'l23network::examples::run_network_scheme', :type => :class do
  context 'parse minimal (empty) network scheme' do
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

    let(:settings_yaml) {
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
  emdpoints: {}
  roles: {}
eof
    }

    let(:params) do {
      :settings_yaml => settings_yaml,
    } end

    it do
      should compile
    end

    it do
      should contain_l2_bond('bond23').with({
        'ensure' => 'present',
        #'slaves' => ['eth2', 'eth3'],
        'mtu'    => 4000,
      })
    end

    it do
      #['eth2', 'eth3'].each do |iface|
      iface='eth3'
        should contain_l2_port(iface).with({
          'ensure'  => 'present',
          'mtu'     => 9000,
          'ethtool' =>  {
              'offload' => {
                'generic-receive-offload'      => false,
                'generic-segmentation-offload' => false
              }
            }
        })
      #end
    end

  end

end

###
