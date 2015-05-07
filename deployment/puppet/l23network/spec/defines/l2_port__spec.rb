require 'spec_helper'

describe 'l23network::l2::port', :type => :define do
  let(:title) { 'Spec for l23network::l2::port' }
  let(:facts) { {
    :osfamily => 'Debian',
    :operatingsystem => 'Ubuntu',
    :kernel => 'Linux',
    :l23_os => 'ubuntu',
    :l3_fqdn_hostname => 'stupid_hostname',
  } }
  let(:pre_condition) { [
    "class {'l23network': }"
  ] }


  context 'Port without anythyng' do
    let(:params) do
      {
        :name => 'eth4',
      }
    end

    it do
      should compile.with_all_deps
    end

    it do
      should contain_l23_stored_config('eth4').with({
        'ensure'  => 'present',
        'use_ovs' => nil,
        'if_type' => nil,
        'method'  => nil,
        'ipaddr'  => nil,
        'gateway' => nil,
          })
    end

    it do
      should contain_l2_port('eth4').with({
        'ensure'  => 'present',
      }).that_requires('L23_stored_config[eth4]')
    end
  end

  context 'Native linux subinterface' do
    let(:params) do
      {
        :name => 'eth4.102',
      }
    end

    it do
      should compile
    end

    it do
      should contain_l23_stored_config('eth4.102').with({
        'ensure'    => 'present',
        'if_type'   => nil,
        'use_ovs'   => nil,
        'method'    => nil,
        'ipaddr'    => nil,
        'gateway'   => nil,
        'vlan_id'   => '102',
        'vlan_dev'  => 'eth4',
        'vlan_mode' => 'eth'
      })
    end

    it do
      should contain_l2_port('eth4.102').with({
        'ensure'    => 'present',
        'vlan_id'   => '102',
        'vlan_dev'  => 'eth4',
        'vlan_mode' => 'eth'
      }).that_requires('L23_stored_config[eth4.102]')
    end
  end

  context 'Alternative VLAN definition' do
    let(:params) do
      {
        :name     => 'vlan102',
        :vlan_dev => 'eth4',
        :vlan_id  => '102',
      }
    end

    it do
      should compile
    end

    it do
      should contain_l23_stored_config('vlan102').with({
        'ensure'    => 'present',
        'if_type'   => nil,
        'use_ovs'   => nil,
        'method'    => nil,
        'ipaddr'    => nil,
        'gateway'   => nil,
        'vlan_id'   => '102',
        'vlan_dev'  => 'eth4',
        'vlan_mode' => 'vlan'
      })
    end

    it do
      should contain_l2_port('vlan102').with({
        'ensure'    => 'present',
        'vlan_id'   => '102',
        'vlan_dev'  => 'eth4',
        'vlan_mode' => 'vlan'
      }).that_requires('L23_stored_config[vlan102]')
    end
  end

  context 'Port, which not ensured' do
    let(:params) do
      {
        :name   => 'eth2',
        :ensure => 'absent',
      }
    end

    it do
      should compile
      should contain_l23_stored_config('eth2').with({
        'ensure'  => 'absent',
      })
      should contain_l2_port('eth2').with({
        'ensure'  => 'absent',
      }).that_requires('L23_stored_config[eth2]')
    end
  end

  context 'Port, which has jumbo frames' do
    let(:params) do
      {
        :name => 'eth2',
        :mtu  => 9000,
      }
    end

    it do
      should compile
      should contain_l23_stored_config('eth2').with({
        'method'  => nil,
        'ipaddr'  => nil,
        'gateway' => nil,
        'mtu'     => 9000,
      })
      should contain_l2_port('eth2').with({
        'ensure'  => 'present',
        'mtu'     => 9000,
      }).that_requires('L23_stored_config[eth2]')
    end
  end

  context 'Port, which an a member of bridge' do
    let(:params) do
      {
        :name   => 'eth2',
        :bridge => 'br-floating',
      }
    end

    it do
      should compile
      should contain_l23_stored_config('eth2').with({
        'method'  => nil,
        'ipaddr'  => nil,
        'gateway' => nil,
        'bridge'  => 'br-floating',
      })
      should contain_l2_port('eth2').with({
        'ensure'  => 'present',
        'bridge'  => 'br-floating',
      }).that_requires('L23_stored_config[eth2]')
    end
  end

  context 'Port, which has vendor-specific field' do
    let(:params) do
      {
        :name            => 'eth2',
        :vendor_specific => {
            'aaa' => '1111',
            'bbb' => {
                'bbb1' => 11111,
                'bbb2' => ['b11','b12','b13']
            },
        },
      }
    end

    it do
      should compile
      should contain_l23_stored_config('eth2').with({
        'method'  => nil,
        'ipaddr'  => nil,
        'gateway' => nil,
        'vendor_specific' => {
            'aaa' => '1111',
            'bbb' => {
                'bbb1' => 11111,
                'bbb2' => ['b11','b12','b13']
            },
        },
      })
      should contain_l2_port('eth2').with({
        'ensure'  => 'present',
        'vendor_specific' => {
            'aaa' => '1111',
            'bbb' => {
                'bbb1' => 11111,
                'bbb2' => ['b11','b12','b13']
            },
        },
      }).that_requires('L23_stored_config[eth2]')
    end
  end

end
# vim: set ts=2 sw=2 et
