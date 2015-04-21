require 'spec_helper'

describe 'l23network::l3::ifconfig', :type => :define do
  context 'simple ifconfig usage' do
    let(:title) { 'ifconfig simple test' }
    let(:facts) { {
      :osfamily => 'Debian',
      :operatingsystem => 'Ubuntu',
      :kernel => 'Linux'
    } }

    let(:params) { {
      :interface => 'eth4',
      :ipaddr => 'none'
    } }

    let(:pre_condition) { [
      "class {'l23network': }"
    ] }

    it do
      should compile
    end

    it do
      should contain_l23_stored_config('eth4').only_with({
        'ensure'         => 'present',
        'name'           => 'eth4',
        'method'         => 'manual',
        'ipaddr'         => 'none',
        'gateway'        => nil,
        'use_ovs'        => nil,
      })
    end

    it do
      should contain_l3_ifconfig('eth4').with({
        'ensure'  => 'present',
        'ipaddr'  => 'none',
        'gateway' => nil,
      })
    end

    it do
      should contain_l3_ifconfig('eth4').that_requires('L23_stored_config[eth4]')
      should contain_l3_ifconfig('eth4').that_requires('L23network::L2::Port[eth4]')
    end

  end

end

# vim: set ts=2 sw=2 et