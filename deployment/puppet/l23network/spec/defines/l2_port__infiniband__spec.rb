require 'spec_helper'

describe 'l23network::l2::port', :type => :define do
  let(:title) { 'Spec for l23network::l2::port with workaround for IB' }
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


  context 'Infiniband parent' do
    let(:params) do
      {
        :name => 'ib0',
      }
    end

    it do
      should compile.with_all_deps
    end

    it do
      should contain_l23_stored_config('ib0').with({
        'ensure'  => 'present',
        'use_ovs' => nil,
        'if_type' => nil,
        'method'  => nil,
        'ipaddr'  => nil,
        'gateway' => nil,
          })
    end

    it do
      should contain_l2_port('ib0').with({
        'ensure'  => 'present',
      }).that_requires('L23_stored_config[ib0]')
    end
  end

  context 'Infiniband subinterface' do
    let(:params) do
      {
        :name     => 'ib0.8000',
        :vlan_dev => false
      }
    end

    it do
      should compile
    end

    it do
      should contain_l23_stored_config('ib0.8000').with({
        'ensure'    => 'present',
        'if_type'   => nil,
        'use_ovs'   => nil,
        'method'    => nil,
        'ipaddr'    => nil,
        'gateway'   => nil,
        'vlan_id'   => nil,
        'vlan_dev'  => nil,
        'vlan_mode' => nil
      })
    end

    it do
      should contain_l2_port('ib0.8000').with({
        'ensure'    => 'present',
        'vlan_id'   => nil,
        'vlan_dev'  => nil,
        'vlan_mode' => nil
      }).that_requires("L23_stored_config[ib0.8000]")
    end
  end


end
# vim: set ts=2 sw=2 et
