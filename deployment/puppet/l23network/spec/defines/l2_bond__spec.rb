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

  context 'Just create a lnx-bond with two slave interfaces' do
    let(:params) do
      {
        :name            => 'bond0',
        :interfaces      => ['eth3', 'eth4'],
        :bond_properties => {
            'mode' => 'balance-rr',
        },
        #:monolith_bond_providers => ['xxx','ovs'],
        :provider => 'lnx'
      }
    end

    it do
      should compile
    end

    it do
      should contain_l23_stored_config('bond0').only_with({
        'if_type'     => 'bond',
        'onboot'      => nil,
        'bond_mode'   => 'balance-rr',
        'bond_master' => nil,
        'bond_slaves' => ['eth3', 'eth4'],
        'use_ovs'     => nil,
        'method'      => nil,
        'ipaddr'      => nil,
        'gateway'     => nil,
        'vendor_specific' => nil,
      })
    end

    ['eth3', 'eth4'].each do |slave|
      it do
        should contain_l23_stored_config(slave).only_with({
          'use_ovs' => nil,
          'onboot'  => nil,
          'method'  => nil,
          'ipaddr'  => nil,
          'gateway' => nil,
          'vendor_specific' => nil,
        })
      end

      it do
        should contain_l2_port(slave).with({
          'ensure'   => 'present',
          #'master'   => 'bond0',
          #'slave'    => true,
          'use_ovs'  => nil,
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
        'if_type'     => 'bond',
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
          'ensure'   => 'present',
          'mtu'         => 9000,
        }).that_requires("L23_stored_config[#{slave}]")
      end

      it do
        should contain_l2_port(slave).that_requires('L2_bond[bond0]')
      end
    end
  end

end
# vim: set ts=2 sw=2 et