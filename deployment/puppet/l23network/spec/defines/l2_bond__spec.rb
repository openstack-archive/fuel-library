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

  let(:pre_condition) do
    definition_pre_condition
  end

  before(:each) do
    puppet_debug_override()
  end

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
        'ensure'         => 'present',
        'if_type'        => 'bond',
        'bond_mode'      => 'balance-rr',
        'bond_slaves'    => ['eth3', 'eth4'],
        'bond_miimon'    => '100',
        'bond_updelay'   => '3000',
        'bond_downdelay' => '1000',
      })
    end

    it do
      should contain_l2_bond('bond0').with({
        'slaves'          => ['eth3', 'eth4'],
        'bond_properties' => {:mode=>"balance-rr",
                              :miimon=>"100",
                              :use_carrier=>"1",
                              :updelay=>"3000",
                              :downdelay=>"1000"},
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

  context 'Just create a ovs-bond with two slave interfaces' do
    let(:params) do
      {
        :name            => 'ovs-bond0',
        :bridge          => 'br-ovs-bond0',
        :interfaces      => ['eth31', 'eth41'],
        :bond_properties => {},
        :provider        => 'ovs'
      }
    end

    it do
      should compile.with_all_deps
    end

    it do
      should contain_l23_stored_config('ovs-bond0').with({
        'ensure'         => 'present',
        'if_type'        => 'bond',
        'bond_mode'      => 'active-backup',
        'bond_slaves'    => ['eth31', 'eth41'],
        'bond_miimon'    => '100',
        'bond_updelay'   => '3000',
        'bond_downdelay' => '1000',
      })
    end

    it do
      should contain_l2_bond('ovs-bond0').with({
        'slaves'          => ['eth31', 'eth41'],
        'bridge'          => 'br-ovs-bond0',
        'bond_properties' => {:mode=>"active-backup",
                              :miimon=>"100",
                              :use_carrier=>"1",
                              :lacp=>"off",
                              :updelay=>"3000",
                              :downdelay=>"1000"},
      })
    end

    ['eth31', 'eth41'].each do |slave|
      it do
        should contain_l23_stored_config(slave).with({
          'ensure'      => 'present',
          'if_type'     => nil,
        })
      end

      it do
        should contain_l2_port(slave)
      end

      it do
        should contain_l2_port(slave).with({
          'ensure'   => 'present',
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

    it do
      should contain_l2_bond('bond0').with({
        'slaves'          => ['eth3.101', 'eth4.102'],
        'bond_properties' => {:mode=>'balance-rr',
                              :miimon=>'100',
                              :use_carrier=>'1',
                              :updelay=>'3000',
                              :downdelay=>'1000'},
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


  context 'Create a lnx-bond with specific parameters' do
    let(:params) do
      {
        :name            => 'bond0',
        :interfaces      => ['eth3', 'eth4'],
        :mtu             => 9000,
        :bond_properties => {
          'updelay'   => '111',
          'downdelay' => '222',
          'ad_select' => '2',
        },
        :provider        => 'lnx'
      }
    end

    it do
      should compile
    end

    it do
      should contain_l23_stored_config('bond0').with({
        'mtu'            => 9000,
        'bond_updelay'   => '111',
        'bond_downdelay' => '222',
        'bond_ad_select' => nil,
      })
    end

    it do
      should contain_l2_bond('bond0').with({
        'slaves'          => ['eth3', 'eth4'],
        'bond_properties' => {:mode=>'balance-rr',
                              :miimon=>'100',
                              :use_carrier=>'1',
                              :updelay=>'111',
                              :downdelay=>'222'},
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

    it do
      should contain_l2_bond('bond0').with({
        'slaves'          => ['eth3', 'eth4'],
        'bond_properties' => {:mode=>'802.3ad',
                              :xmit_hash_policy=>'layer2',
                              :lacp_rate=>'slow',
                              :ad_select=>'bandwidth',
                              :miimon=>'100',
                              :use_carrier=>'1',
                              :updelay=>'3000',
                              :downdelay=>'1000'},
      })
    end
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
        'bond_miimon'           => '100',
      })
      should contain_l23_stored_config('bond0').without_bond_lacp_rate()
      should contain_l23_stored_config('bond0').without_bond_xmit_hash_policy()
    end

    it do
      should contain_l2_bond('bond0').with({
        'slaves'          => ['eth3', 'eth4'],
        'bond_properties' => {:mode=>'active-backup',
                              :miimon=>'100',
                              :use_carrier=>'1',
                              :updelay=>'3000',
                              :downdelay=>'1000'},
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
            'lacp'             => 'active',
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
        'bond_xmit_hash_policy' => 'layer2+3',
        'bond_miimon'           => '300',
      })
      should contain_l23_stored_config('bond0').without_bond_lacp() # because 'lacp' -- only OVS property
      should contain_l23_stored_config('bond0').without_bond_lacp_rate() # because 'balance-tlb' is non-lacp mode
    end
  end


  #  Open vSwitch provider

  context 'Create a ovs-bond without defined bridge' do
    let(:params) do
      {
        :name            => 'bond-ovs',
        :interfaces      => ['eth2', 'eth3'],
        :bond_properties => {
            'mode'             => 'balance-tlb',
            'lacp_rate'        => 'fast',
            'xmit_hash_policy' => 'layer2+3',
            'miimon'           => '300',
        },
        :provider => 'ovs'
      }
    end

    it do
        should compile.and_raise_error(%r{Bridge is not defined for bond bond-ovs. This is necessary for Open vSwitch bonds})
    end
  end

  context 'Create a ovs-bond with mode = balance-tcp, lacp_rate = fast xmit_hash_policy = layer2+3' do
    let(:params) do
      {
        :name            => 'bond-ovs',
        :interfaces      => ['eth2', 'eth3'],
        :bridge          => 'br-bond-ovs',
        :bond_properties => {
            'mode'             => 'balance-tcp',
            'lacp'             => 'active',
            'lacp_rate'        => 'fast',
            'xmit_hash_policy' => 'layer2+3',
            'miimon'           => '300',
        },
        :provider => 'ovs'
      }
    end

    it do
        should compile
    end

    ['eth2', 'eth3'].each do |slave|
      it do
        should contain_l23_stored_config(slave).with({
          'ensure'      => 'present',
          'if_type'     => nil,
          'bond_master' => nil,
        })
      end

      it do
        should contain_l2_port(slave)
      end

      it do
        should contain_l2_port(slave).with({
          'ensure'   => 'present',
          'provider' => nil,
        }).that_requires("L23_stored_config[#{slave}]")
      end

    end

    it 'Contain l23_stored_config with lacp=off by default' do
      should contain_l23_stored_config('bond-ovs').with({
        'ensure'                => 'present',
        'bridge'                => 'br-bond-ovs',
        'if_type'               => 'bond',
        'bond_mode'             => 'balance-tcp',
        'bond_lacp'             => 'active',
        'bond_lacp_rate'        => 'fast',
        'bond_miimon'           => '300',
        'bond_updelay'          => '9000',
        'bond_downdelay'        => '3000',
      })
      should contain_l23_stored_config('bond-ovs').without_bond_xmit_hash_policy()
    end

    it do
      should contain_l2_bond('bond-ovs').with({
        'bond_properties' => {
          :mode             => 'balance-tcp',
          :lacp             => 'active',
          :lacp_rate        => 'fast',
          :use_carrier      => '1',
          :miimon           => '300',
          :updelay          => '9000',
          :downdelay        => '3000',
        },
      })
    end

  end

  context 'Create a ovs-bond with mode = balance-tlb, lacp = active' do
    let(:params) do
      {
        :name            => 'bond-ovs2',
        :interfaces      => ['eth23', 'eth33'],
        :bridge          => 'br-bond-ovs2',
        :bond_properties => {
            'mode'             => 'balance-tlb',
            'lacp'             => 'active',
        },
        :provider => 'ovs'
      }
    end

    it do
        should compile
    end

    it 'Contain l23_stored_config with lacp=active' do
      should contain_l23_stored_config('bond-ovs2').with({
        'ensure'                => 'present',
        'bridge'                => 'br-bond-ovs2',
        'if_type'               => 'bond',
        'bond_lacp'             => 'active',
        'bond_mode'             => 'balance-tlb',
      })
    end

  end

end
