require 'spec_helper'

describe 'l23network', :type => :class do

  context 'default init of l23network module' do
#    let(:title) { 'empty network scheme' }
    let(:facts) { {
      :osfamily => 'Debian',
      :operatingsystem => 'Ubuntu',
      :kernel => 'Linux',
      :l23_os => 'ubuntu',
      :l3_fqdn_hostname => 'stupid_hostname',
    } }

    before(:each) do
      puppet_debug_override()
    end

    it do
      should compile.with_all_deps
    end

    it do
      should contain_package('bridge-utils').with_ensure('present')
      should contain_package('ethtool').with_ensure('present')
      should contain_package('ifenslave').with_ensure('present')
      should contain_package('vlan').with_ensure('present')
      should contain_anchor('l23network::l2::init').that_comes_before('Anchor[l23network::init]')
      should contain_anchor('l23network::l2::init').that_requires('Package[vlan]')
      should contain_anchor('l23network::l2::init').that_requires('Package[ifenslave]')
      should contain_anchor('l23network::l2::init').that_requires('Package[ethtool]')
    end
  end

  context 'init l23network module with enabled OVS' do
    #let(:title) { 'empty network scheme' }
    let(:facts) { {
      :osfamily => 'Debian',
      :operatingsystem => 'Ubuntu',
      :kernel => 'Linux',
      :l23_os => 'ubuntu',
      :l3_fqdn_hostname => 'stupid_hostname',
    } }

    let(:params) { {
      :use_ovs => true
    } }

    before(:each) do
      puppet_debug_override()
    end

    it do
      should compile.with_all_deps
    end

    it do
      should contain_package('openvswitch-common').with({
        'name'   => 'openvswitch-switch'
      })
      should contain_package('bridge-utils').with_ensure('present')
      should contain_package('ethtool').with_ensure('present')
      should contain_package('ifenslave').with_ensure('present')
      should contain_package('vlan').with_ensure('present')
    end

    it do
      should contain_service('openvswitch-service').with({
        'ensure' => 'running',
        'name'   => 'openvswitch-switch',
        'enable' => true
      }).that_comes_before('Anchor[l23network::l2::init]')
    end

    it do
      should contain_disable_hotplug('global')
    end

    it do
      should contain_enable_hotplug('global').that_requires('Disable_hotplug[global]')
    end

  end

  context 'when removing packages of the l23network module' do
    let(:facts) { {
      :osfamily => 'Debian',
      :operatingsystem => 'Ubuntu',
      :l23_os => 'ubuntu',
    } }

    let(:params) { {
      :ensure_package => 'absent',
      :use_ovs => 'false',
    } }

    it 'without OVS, should not contain packages' do
      should contain_package('bridge-utils').with(
        :ensure => 'absent' )
      should contain_package('ethtool').with(
        :ensure => 'absent' )
      should contain_package('ifenslave').with(
        :ensure => 'absent' )
      should contain_package('vlan').with(
        :ensure => 'absent' )
    end

    let(:params) { {
      :ensure_package => 'absent',
      :use_ovs => 'true',
    } }

    it 'with OVS, should not contain packages' do
      should contain_package('bridge-utils').with(
        :ensure => 'absent' )
      should contain_package('ethtool').with(
        :ensure => 'absent' )
      should contain_package('ifenslave').with(
        :ensure => 'absent' )
      should contain_package('vlan').with(
        :ensure => 'absent' )
      should contain_package('openvswitch-common').with(
        :ensure => 'absent' )
    end

  end

end
# vim: set ts=2 sw=2 et
