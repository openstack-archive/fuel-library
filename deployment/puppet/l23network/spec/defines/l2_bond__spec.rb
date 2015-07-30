require 'spec_helper'

describe 'l23network::l2::bond', :type => :define do
  let(:title) { 'Spec for l23network::l2::bond' }
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


  context 'Just create a lnx-bond with two slave interfaces' do
    let(:params) do
      {
        :name            => 'bond0',
        :interfaces      => ['eth3', 'eth4'],
        :bond_properties => {},
        :provider => 'lnx'
      }
    end

    it do
      should compile.with_all_deps
    end

    it do
      should contain_l23_stored_config('bond0').with({
        'ensure'      => 'present',
        'if_type'     => 'bond',
        'bond_mode'   => 'balance-rr',
        'bond_slaves' => ['eth3', 'eth4'],
        'bond_miimon' => '100',
      })
    end

    ['eth3', 'eth4'].each do |slave|
      it do
        should contain_l23_stored_config(slave).with({
          'ensure'      => 'present',
          'if_type'     => nil,
          'bond_master' => 'bond0',
        })
      end

      it do
        should contain_l2_port(slave)
      end

      it do
        should contain_l2_port(slave).with({
          'ensure'   => 'present',
          'provider' => 'lnx',
        }).that_requires("L23_stored_config[#{slave}]")
      end
    end
  end

  context 'Just create a lnx-bond with two vlan subinterfaces as slave interfaces' do
    let(:params) do
      {
        :name            => 'bond0',
        :interfaces      => ['eth3.101', 'eth4.102'],
        :bond_properties => {},
        :provider => 'lnx'
      }
    end

    it do
      should compile.with_all_deps
    end

    it do
      should contain_l23_stored_config('bond0').with({
        'ensure'      => 'present',
        'if_type'     => 'bond',
        'bond_mode'   => 'balance-rr',
        'bond_slaves' => ['eth3.101', 'eth4.102'],
        'bond_miimon' => '100',
      })
    end

    ['eth3.101', 'eth4.102'].each do |slave|
      it do
        should contain_l23_stored_config(slave).with({
          'ensure'      => 'present',
          'if_type'     => nil,
          'bond_master' => 'bond0',
        })
      end

      it do
        should contain_l2_port(slave)
      end

      it do
        should contain_l2_port(slave).with({
          'ensure'   => 'present',
          'provider' => 'lnx',
        }).that_requires("L23_stored_config[#{slave}]")
      end
    end
  end


  context 'Just create a lnx-bond with specific MTU' do
    let(:params) do
      {
        :name            => 'bond0',
        :interfaces      => ['eth3', 'eth4'],
        :mtu             => 9000,
        :bond_properties => {},
        :provider        => 'lnx'
      }
    end

    it do
      should compile
    end

    it do
      should contain_l23_stored_config('bond0').with({
        'mtu'         => 9000,
      })
    end

    it do
      should contain_l2_bond('bond0').with({
        'mtu'         => 9000,
      }).that_requires('L23_stored_config[bond0]')
    end

    ['eth3', 'eth4'].each do |slave|
      it do
        should contain_l23_stored_config(slave).with({
          'mtu'         => 9000,
        })
      end

      it do
        should contain_l2_port(slave).with({
          'mtu'         => 9000,
        }).that_requires("L23_stored_config[#{slave}]")
      end

    end
  end

  context 'Create a lnx-bond with LACP' do
    let(:params) do
      {
        :name            => 'bond0',
        :interfaces      => ['eth3', 'eth4'],
        :bond_properties => {
            'mode' => '802.3ad',
        },
        :provider => 'lnx'
      }
    end

    it do
      should compile
    end

    it do
      should contain_l23_stored_config('bond0').with({
        'ensure'                => 'present',
        'if_type'               => 'bond',
        'bond_mode'             => '802.3ad',
        'bond_lacp_rate'        => 'slow',
        'bond_xmit_hash_policy' => 'layer2',
      })
    end
    # it do
    #   should contain_l2_bond('bond0').with_ensure('present')
    #   should contain_l2_bond('bond0').with_bond_properties({
    #       :mode             => '802.3ad',
    #       :lacp_rate        => 'slow',
    #       :miimon           => '100',
    #       :xmit_hash_policy => 'layer2'
    #   })
    # end

    # we shouldn't test bond slaves here, because it equalent to previous tests
  end

  context 'Create a lnx-bond with mode = active-backup, lacp_rate = fast xmit_hash_policy = layer2' do
    let(:params) do
      {
        :name            => 'bond0',
        :interfaces      => ['eth3', 'eth4'],
        :bond_properties => {
            'mode'             => 'active-backup',
            'lacp_rate'        => 'fast',
            'xmit_hash_policy' => 'layer2',
        },
        :provider => 'lnx'
      }
    end

    it do
      should compile
    end

    it do
      should contain_l23_stored_config('bond0').with({
        'ensure'                => 'present',
        'if_type'               => 'bond',
        'bond_mode'             => 'active-backup',
        'bond_lacp_rate'        => nil,
        'bond_xmit_hash_policy' => nil,
        'bond_miimon'           => '100',
      })
    end
  end

  context 'Create a lnx-bond with mode = balance-tlb, lacp_rate = fast xmit_hash_policy = layer2+3' do
    let(:params) do
      {
        :name            => 'bond0',
        :interfaces      => ['eth3', 'eth4'],
        :bond_properties => {
            'mode'             => 'balance-tlb',
            'lacp_rate'        => 'fast',
            'xmit_hash_policy' => 'layer2+3',
            'miimon'           => '300',
        },
        :provider => 'lnx'
      }
    end

    it do
      should compile
    end

    it do
      should contain_l23_stored_config('bond0').with({
        'ensure'                => 'present',
        'if_type'               => 'bond',
        'bond_mode'             => 'balance-tlb',
        'bond_lacp_rate'        => nil,
        'bond_xmit_hash_policy' => 'layer2+3',
        'bond_miimon'           => '300',
      })
    end
  end


end
# vim: set ts=2 sw=2 et
