require 'spec_helper'

describe 'l23network', :type => :class do

  context 'default init of l23network module' do
    let(:facts) { {
      :osfamily => 'Debian',
      :operatingsystem => 'Ubuntu',
      :kernel => 'Linux',
      :l23_os => 'ubuntu',
      :l3_fqdn_hostname => 'stupid_hostname',
    } }

    it do
      should compile.with_all_deps
    end

    it do
      should contain_package('bridge-utils').with_ensure('present')
      should contain_package('ethtool').with_ensure('present')
      should contain_package('iputils-arping').with_ensure('present')
      should_not contain_package('ifenslave')
      should_not contain_package('vlan')
      should contain_anchor('l23network::l2::init').that_comes_before('Anchor[l23network::init]')
      should contain_anchor('l23network::l2::init').that_requires('Package[ethtool]')
      should contain_anchor('l23network::init').that_requires('Package[iputils-arping]')
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

    it do
      should compile.with_all_deps
    end

    it do
      should contain_package('openvswitch-common').with({
        'name'   => 'openvswitch-switch'
      })
      should contain_package('bridge-utils').with_ensure('present')
      should contain_package('ethtool').with_ensure('present')
      should contain_package('iputils-arping').with_ensure('present')
      should_not contain_package('ifenslave')
      should_not contain_package('vlan')
      should contain_anchor('l23network::init').that_requires('Package[iputils-arping]')
    end

    it do
      should contain_service('openvswitch-service').with({
        'ensure' => 'running',
        'name'   => 'openvswitch-switch',
        'enable' => true
      }).that_comes_before('Anchor[l23network::l2::init]')
    end

  end

end

###