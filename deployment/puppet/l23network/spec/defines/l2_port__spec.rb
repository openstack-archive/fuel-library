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

  context 'Port without anythyng' do
    let(:params) do
      {
        :name => 'eth4',
      }
    end

    it do
      should compile
    end

    it do
      should contain_l23_stored_config('eth4').only_with({
        'use_ovs' => nil,
        'method'  => nil,
        'ipaddr'  => nil,
        'gateway' => nil,
      })
    end

    it do
      should contain_l2_port('eth4').only_with({
        'ensure'  => 'present',
        'use_ovs' => nil,
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
      should contain_l23_stored_config('eth4.102').only_with({
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
      should contain_l2_port('eth4.102').only_with({
        'ensure'  => 'present',
        'use_ovs'   => nil,
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
      should contain_l23_stored_config('vlan102').only_with({
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
      should contain_l2_port('vlan102').only_with({
        'ensure'  => 'present',
        'use_ovs'   => nil,
        'vlan_id'   => '102',
        'vlan_dev'  => 'eth4',
        'vlan_mode' => 'vlan'
      }).that_requires('L23_stored_config[vlan102]')
    end
  end

end
###