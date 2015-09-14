require 'spec_helper'

describe 'l23network::examples::run_network_scheme', :type => :class do
let(:network_scheme) do
<<eof
---
network_scheme:
  version: 1.1
  provider: lnx
  interfaces:
    eth1: {}
  transformations:
    - action: add-br
      name: br-ovs
      provider: ovs
    - action: add-br
      name: br1
      provider: lnx
    - action: add-patch
      bridges:
        - br-ovs
        - br1
      provider: ovs
  endpoints:
    br1:
      IP:
       - 192.168.88.2/24
  roles: {}
eof
end

  context 'Patch between OVS and LNX bridges.' do
    let(:title) { 'Centos has delay for port after boot' }
    let(:facts) {
      {
        :osfamily => 'Debian',
        :operatingsystem => 'Ubuntu',
        :kernel => 'Linux',
        :l23_os => 'ubuntu',
        :l3_fqdn_hostname => 'stupid_hostname',
      }
    }

    let(:params) do {
      :settings_yaml => network_scheme,
    } end

    before(:each) do
      if ENV['SPEC_PUPPET_DEBUG']
        Puppet::Util::Log.level = :debug
        Puppet::Util::Log.newdestination(:console)
      end
    end

    it do
      should compile.with_all_deps
    end

    it do
      should contain_l23_stored_config('br-ovs').with({
        'ensure'       => 'present',
        'provider'     => 'ovs_ubuntu'
      })
    end

    it do
      should contain_l23_stored_config('br1').with({
        'ensure'         => 'present',
        'ipaddr'         => '192.168.88.2/24',
        'provider'       => 'lnx_ubuntu'
      })
    end

    it do
      should contain_l2_bridge('br-ovs').with({
        'ensure'   => 'present',
        'provider' => 'ovs'
      })
    end

    it do
      should contain_l2_bridge('br1').with({
        'ensure'   => 'present',
        'provider' => 'lnx'
      })
    end

    it do
      should contain_l3_ifconfig('br1').with({
        'ensure'   => 'present',
        'ipaddr'   => ['192.168.88.2/24',],
      })
    end

    it do
      should contain_l2_patch('patch__br-ovs--br1').with({
        'ensure'   => 'present',
        'bridges'  => ['br-ovs', 'br1'],
        'vlan_ids' => ['0', '0'],
        'provider' => 'ovs'
      })
    end

    it do
      # different jacks name here, because decision for using mono-jack patchcord
      # made on provider level
      should contain_l2_patch('patch__br-ovs--br1').with_jacks(['p_33470efd-0', 'p_33470efd-1'])
    end

    it do
      should contain_l23_stored_config('p_33470efd-0').with({
        'ensure'         => 'present',
        'if_type'        => 'ethernet',
        'bridge'         => ["br-ovs", "br1"],
        'jacks'          => ['p_33470efd-0', 'p_33470efd-1'],
        'provider'       => 'ovs_ubuntu'
      })
    end

  end

end

###
