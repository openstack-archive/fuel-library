require 'spec_helper'

describe 'l23network::l2::bridge', :type => :define do
  let(:title) { 'Spec for l23network::l2::bridge' }
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

  context 'Just a bridge, created by name' do
    let(:params) do
      {
        :name => 'br-mgmt',
      }
    end

    it do
      should compile
    end

    it do
      should contain_l23_stored_config('br-mgmt').only_with({
        'use_ovs'    => nil,
        'method'     => nil,
        'ipaddr'     => nil,
        'gateway'    => nil,
        'bridge_stp' => nil,
        'vendor_specific' => {},
      })
    end

    it do
      should contain_l2_bridge('br-mgmt').with({
        'ensure'       => 'present',
        'external_ids' => {'bridge-id'=>'br-mgmt'},
      }).that_requires('L23_stored_config[br-mgmt]')
    end
  end

  # This feature will be implemented later
  # context 'Bridge, created with specigic MTU value' do
  #   let(:params) do
  #     {
  #       :name => 'br-mgmt',
  #       :mtu  => 9000,
  #     }
  #   end

  #   it do
  #     should compile
  #   end

  #   it do
  #     should contain_l23_stored_config('br-mgmt').with({
  #       'mtu' => 9000,
  #     })
  #   end

  #   it do
  #     should contain_l2_bridge('br-mgmt').with({
  #       'ensure' => 'present',
  #       'mtu'    => 9000,
  #     }).that_requires('L23_stored_config[br-mgmt]')
  #   end
  # end


  context 'Bridge, created with enabled stp' do
    let(:params) do
      {
        :name => 'br-mgmt',
        :stp  => true,
      }
    end

    it do
      should compile.with_all_deps
    end

    it do
      should contain_l23_stored_config('br-mgmt').with({
        'bridge_stp' => true,
      })
    end

    it do
      should contain_l2_bridge('br-mgmt').with({
        'ensure' => 'present',
        'stp'    => true,
      }).that_requires('L23_stored_config[br-mgmt]')
    end
  end

  context 'Pass vendor-specific property to bridge resource' do
    let(:params) do
      {
        :name => 'br-mgmt',
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
    end

    it do
      should contain_l23_stored_config('br-mgmt').with({
        'vendor_specific' => {
            'aaa' => '1111',
            'bbb' => {
                'bbb1' => 11111,
                'bbb2' => ['b11','b12','b13']
            },
        },
      })
    end

    it do
      should contain_l2_bridge('br-mgmt').with({
        'ensure' => 'present',
        'vendor_specific' => {
            'aaa' => '1111',
            'bbb' => {
                'bbb1' => 11111,
                'bbb2' => ['b11','b12','b13']
            },
        },
      }).that_requires('L23_stored_config[br-mgmt]')
    end
  end

  context 'Pass non-default property to bridge resource' do
    # Warning!! in the latest releases external_ids property will
    # be moved to vendor_specific hash
    let(:params) do
      {
        :name          => 'br-mgmt',
        :external_ids  => { 'bridge-id' => 'qwe',  'aaa' => 'bbb'},
      }
    end

    it do
      should compile
    end

    # In this case no stored_config, because only OVS has this functionality,
    # bun one store this values in ovsdb automatically
    it do
      should contain_l2_bridge('br-mgmt').with({
        'ensure' => 'present',
        'external_ids' => {
          'bridge-id' => 'qwe',
          'aaa' => 'bbb'
        },
      })
    end
  end


  context 'create ovs bridge' do
    let(:params) do
      {
        :name    => 'br-floating',
        :use_ovs => true,
#        :provider => 'ovs',
      }
    end

    it do
      should compile
    end

    it do
      should contain_l23_stored_config('br-floating').only_with({
        'ensure'       => 'present',
        'bridge_stp'   => nil,
        'if_type'      => 'bridge',
        'bridge_ports' => ['none'],
        'provider'     => nil,
        'vendor_specific' => {},
      })
    end

    it do
      should contain_l2_bridge('br-floating').only_with({
        'ensure'       => 'present',
        'use_ovs'      => true,
        'external_ids' => { 'bridge-id' => 'br-floating' },
        'stp'          => nil,
        'provider'     => nil,
        'vendor_specific' => {},
      }).that_requires('L23_stored_config[br-floating]')
    end
  end

  context 'create ovs bridge' do
    let(:params) do
      {
        :name    => 'br-floating',
        :use_ovs => true,
#        :provider => 'ovs',
      }
    end

    it do
      should compile
    end

    it do
      should contain_l23_stored_config('br-floating').only_with({
        'ensure'       => 'present',
        'bridge_stp'   => nil,
        'if_type'      => 'bridge',
        'bridge_ports' => ['none'],
        'provider'     => nil,
        'vendor_specific' => {},
      })
    end

    it do
      should contain_l2_bridge('br-floating').only_with({
        'ensure'       => 'present',
        'use_ovs'      => true,
        'external_ids' => { 'bridge-id' => 'br-floating' },
        'stp'          => nil,
        'provider'     => nil,
        'vendor_specific' => {},
      }).that_requires('L23_stored_config[br-floating]')
    end
  end
end
