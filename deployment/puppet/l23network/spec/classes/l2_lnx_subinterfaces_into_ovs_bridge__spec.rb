require 'spec_helper'

describe 'l23network::examples::run_network_scheme', :type => :class do
  context 'network scheme with OVS bridge and native lnx subinterface with ethN.XXX naming into it' do
    let(:title) { 'test network scheme' }
    let(:facts) {
      {
        :osfamily => 'Debian',
        :operatingsystem => 'Ubuntu',
        :kernel => 'Linux',
        :l23_os => 'ubuntu',
        :l3_fqdn_hostname => 'stupid_hostname',
      }
    }

    let(:params) {{
      :settings_yaml => '''
        network_scheme:
          version: 1.1
          provider: lnx
          interfaces:
            eth1: {}
          transformations:
            - action: add-br
              name: xxx
              provider: ovs
            - action: add-port
              name: eth1.101
              bridge: xxx
      '''
    }}

    before(:each) do
      puppet_debug_override()
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_l23network__l2__port('eth1.101') }
    it { is_expected.to contain_l23network__l2__port('eth1.101').with({
        'provider'  => 'lnx',
    })}
  end
end

describe 'l23network::examples::run_network_scheme', :type => :class do
  context 'network scheme with OVS bridge and native lnx subinterface with vlanXXX naming into it' do
    let(:title) { 'test network scheme' }
    let(:facts) {
      {
        :osfamily => 'Debian',
        :operatingsystem => 'Ubuntu',
        :kernel => 'Linux',
        :l23_os => 'ubuntu',
        :l3_fqdn_hostname => 'stupid_hostname',
      }
    }

    let(:params) {{
      :settings_yaml => '''
        network_scheme:
          version: 1.1
          provider: lnx
          interfaces:
            eth1: {}
          transformations:
            - action: add-br
              name: xxx
              provider: ovs
            - action: add-port
              name: vlan101
              vlan_dev: eth1
              vlan_id: 101
              bridge: xxx
      '''
    }}

    before(:each) do
      puppet_debug_override()
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_l23network__l2__port('vlan101') }
    it { is_expected.to contain_l23network__l2__port('vlan101').with({
        'provider'  => 'lnx',
    })}
  end
end

describe 'l23network::examples::run_network_scheme', :type => :class do
  context 'network scheme with OVS bridge and native lnx interface into it' do
    let(:title) { 'test network scheme' }
    let(:facts) {
      {
        :osfamily => 'Debian',
        :operatingsystem => 'Ubuntu',
        :kernel => 'Linux',
        :l23_os => 'ubuntu',
        :l3_fqdn_hostname => 'stupid_hostname',
      }
    }

    let(:params) {{
      :settings_yaml => '''
        network_scheme:
          version: 1.1
          provider: lnx
          interfaces:
            eth1: {}
          transformations:
            - action: add-br
              name: xxx
              provider: ovs
            - action: add-port
              name: eth1
              bridge: xxx
      '''
    }}

    before(:each) do
      puppet_debug_override()
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_l23network__l2__port('eth1') }
    it { is_expected.to contain_l23network__l2__port('eth1').with({
        'provider'  => 'ovs',
    })}
  end
end

describe 'l23network::examples::run_network_scheme', :type => :class do
  context 'network scheme with OVS bridge and ovs fake interface into it' do
    let(:title) { 'test network scheme' }
    let(:facts) {
      {
        :osfamily => 'Debian',
        :operatingsystem => 'Ubuntu',
        :kernel => 'Linux',
        :l23_os => 'ubuntu',
        :l3_fqdn_hostname => 'stupid_hostname',
      }
    }

    let(:params) {{
      :settings_yaml => '''
        network_scheme:
          version: 1.1
          provider: lnx
          interfaces:
            eth1: {}
          transformations:
            - action: add-br
              name: xxx
              provider: ovs
            - action: add-port
              name: yyy
              bridge: xxx
      '''
    }}

    before(:each) do
      puppet_debug_override()
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_l23network__l2__port('yyy') }
    it { is_expected.to contain_l23network__l2__port('yyy').with({
        'provider'  => 'ovs',
    })}
  end
end

###
