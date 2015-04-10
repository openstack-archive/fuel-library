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

    it do
      should compile.with_all_deps
    end

    it do
      should contain_package('bridge-utils').with_ensure('present')
      should contain_package('ethtool').with_ensure('present')
      should contain_package('ifenslave').with_ensure('present')
      should contain_package('vlan').with_ensure('present')
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
      should contain_package('ifenslave').with_ensure('present')
      should contain_package('vlan').with_ensure('present')
    end

    it do
      should contain_service('openvswitch-service').with({
        'ensure' => 'running',
        'name'   => 'openvswitch-switch',
        'enable' => true
      })
    end

  end

end

###