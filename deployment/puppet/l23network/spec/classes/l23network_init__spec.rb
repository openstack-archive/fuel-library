require 'spec_helper'

describe 'l23network', :type => :class do

  context 'default init of l23network module(Ubuntu)' do
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

    it { should compile.with_all_deps }
    it { should contain_package('bridge-utils').with_ensure('present') }
    it { should contain_package('ethtool').with_ensure('present') }
    it { should contain_package('ifenslave').with_ensure('present') }
    it { should contain_package('vlan').with_ensure('present') }
    it { should contain_package('network-manager').with_ensure('purged') }
    it { should contain_anchor('l23network::l2::init').that_comes_before('Anchor[l23network::init]') }
    it { should contain_anchor('l23network::l2::init').that_requires('Package[vlan]') }
    it { should contain_anchor('l23network::l2::init').that_requires('Package[ifenslave]') }
    it { should contain_anchor('l23network::l2::init').that_requires('Package[ethtool]') }
    it { should contain_class('l23network::l2').with({
                                'install_ovs'      => false,
                                'install_brtool'   => true,
                                'install_dpdk'     => false,
                                'modprobe_bridge'  => true,
                                'install_bondtool' => true,
                                'modprobe_bonding' => true,
                                'install_vlantool' => true,
                                'modprobe_8021q'   => true,
                                'install_ethtool'  => true,
    }) }

  end

  context 'default init of l23network module(CentOS6)' do
    let(:facts) { {
      :operatingsystem => 'CentOS',
      :kernel => 'Linux',
      :l23_os => 'centos6',
      :l3_fqdn_hostname => 'stupid_hostname',
    } }

    before(:each) do
      puppet_debug_override()
    end

    it { should compile.with_all_deps }
    it { should contain_package('bridge-utils').with_ensure('present') }
    it { should contain_package('ethtool').with_ensure('present') }
    it { should_not contain_package('ifenslave').with_ensure('present') }
    it { should_not contain_package('vlan').with_ensure('present') }
    it { should contain_package('NetworkManager').with_ensure('purged') }
    it { should_not contain_service('NetworkManager').with_ensure('stopped') }
    it { should contain_anchor('l23network::l2::init').that_comes_before('Anchor[l23network::init]') }
    it { should contain_anchor('l23network::l2::init').that_requires('Package[ethtool]') }

  end

  context 'default init of l23network module(CentOS7/RHEL7)' do
    let(:facts) { {
      :operatingsystem => 'CentOS',
      :kernel => 'Linux',
      :l23_os => 'centos7',
      :l3_fqdn_hostname => 'stupid_hostname',
    } }

    before(:each) do
      puppet_debug_override()
    end

    it { should compile.with_all_deps }
    it { should contain_package('bridge-utils').with_ensure('present') }
    it { should contain_package('ethtool').with_ensure('present') }
    it { should_not contain_package('ifenslave').with_ensure('present') }
    it { should_not contain_package('vlan').with_ensure('present') }
    it { should contain_package('NetworkManager').with_ensure('purged') }
    it { should contain_service('NetworkManager').with_ensure('stopped') }
    it { should contain_anchor('l23network::l2::init').that_comes_before('Anchor[l23network::init]') }

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
    end
    it { should contain_package('bridge-utils').with_ensure('present') }
    it { should contain_package('ethtool').with_ensure('present') }
    it { should contain_package('ifenslave').with_ensure('present') }
    it { should contain_package('vlan').with_ensure('present') }

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

    it { should contain_class('l23network::l2').with({
                                'install_ovs'      => true,
                                'install_brtool'   => true,
                                'install_dpdk'     => false,
                                'modprobe_bridge'  => true,
                                'install_bondtool' => true,
                                'modprobe_bonding' => true,
                                'install_vlantool' => true,
                                'modprobe_8021q'   => true,
                                'install_ethtool'  => true,
    }) }


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
    end
    it { should contain_package('ethtool').with(
        :ensure => 'absent' ) }
    it { should contain_package('ifenslave').with(
        :ensure => 'absent' ) }
    it { should contain_package('vlan').with(
        :ensure => 'absent' ) }

    let(:params) { {
      :ensure_package => 'absent',
      :use_ovs => 'true',
    } }

    it 'with OVS, should not contain packages' do
      should contain_package('bridge-utils').with(
        :ensure => 'absent' )
    end
    it { should contain_package('ethtool').with(
        :ensure => 'absent' ) }
    it { should contain_package('ifenslave').with(
        :ensure => 'absent' ) }
    it { should contain_package('vlan').with(
        :ensure => 'absent' ) }
    it { should contain_package('openvswitch-common').with(
        :ensure => 'absent' ) }
  end

end

