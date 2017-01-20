require 'spec_helper'

describe 'l23network::examples::run_network_scheme', :type => :class do

  context 'pass vendor_specific through interface_properties' do
    let(:title) { 'xxx' }
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
      :settings_yaml => '''
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
              interface_properties:
                vendor_specific:
                  aaa: bbb
          endpoints: {}
          roles: {}
      ''',
    } end

    before(:each) do
      puppet_debug_override()
    end

    it do
      is_expected.to compile.with_all_deps
    end

    it do
      is_expected.to contain_l2_bond('bond23').with({
        'ensure' => 'present',
        'slaves' => ['eth2', 'eth3'],
      })
    end

    ['eth2', 'eth3'].each do |iface|
      it do
        is_expected.to contain_l2_port(iface).with({
          'ensure'  => 'present',
          'bond_master'  => 'bond23',
          'vendor_specific' => {
            'aaa' => 'bbb',
          }
        })
      end
    end

  end

  context 'merge vendor_specific from port to interface_properties' do
    let(:title) { 'xxx' }
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
      :settings_yaml => '''
        network_scheme:
          version: 1.1
          provider: lnx
          interfaces:
            eth2:
              vendor_specific:
                ifnumber: 2
            eth3:
              vendor_specific:
                ifnumber: 3
            eth4:
              vendor_specific:
                ifnumber: 4
            eth5:
              vendor_specific:
                ifnumber: 5
          transformations:
            - action: add-bond
              name: bond23
              interfaces:
                - eth2
                - eth3
              interface_properties:
                mtu: 9000
                vendor_specific:
                  aaa: bbb
            - action: add-bond
              name: bond45
              mtu: 9000
              interfaces:
                - eth4
                - eth5
              interface_properties:
                vendor_specific:
                  aaa: bbb
          endpoints: {}
          roles: {}
      ''',
    } end

    before(:each) do
      puppet_debug_override()
    end

    it do
      is_expected.to compile.with_all_deps
    end

    it do
      is_expected.to contain_l2_bond('bond23').with({
        'ensure' => 'present',
        'slaves' => ['eth2', 'eth3'],
      })
    end

    ['eth2', 'eth3'].each do |iface|
      it do
        is_expected.to contain_l2_port(iface).with({
          'ensure'  => 'present',
          'bond_master'  => 'bond23',
          'mtu' => 9000,
          'vendor_specific' => {
            'aaa' => 'bbb',
            'ifnumber' => iface[-1]
          }
        })
      end
    end

    it do
      is_expected.to contain_l2_bond('bond45').with({
        'ensure' => 'present',
        'mtu'    => '9000',
        'slaves' => ['eth4', 'eth5'],
      })
    end

    ['eth4', 'eth5'].each do |iface|
      it do
        is_expected.to contain_l2_port(iface).with({
          'ensure'  => 'present',
          'bond_master'  => 'bond45',
          'mtu' => 9000,
          'vendor_specific' => {
            'aaa' => 'bbb',
            'ifnumber' => iface[-1]
          }
        })
      end
    end

  end

end

###
