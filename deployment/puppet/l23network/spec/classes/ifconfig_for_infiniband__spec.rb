require 'spec_helper'

describe 'l23network::examples::run_network_scheme', :type => :class do
  context 'network scheme with IB device, listed into interfaces, transformations and endpoints sections' do
    let(:title) { 'empty network scheme' }
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
            ib2.8001: {}
          transformations:
            - action: add-port
              name:   ib2.8001
          endpoints:
            ib2.8001:
              IP:
                - 192.168.101.3/24
          roles: {}
      '''
    }}

    before(:each) do
      puppet_debug_override()
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_l23network__l2__port('ib2.8001') }
    it { is_expected.to contain_l23network__l2__port('ib2.8001').with({
        'vlan_dev'  => false,
        'vlan_id'   => nil
    })}
    it { is_expected.to contain_l2_port('ib2.8001') }
    it { is_expected.to contain_l2_port('ib2.8001').with({
        'vlan_dev'  => nil,
        'vlan_id'   => nil
    })}
    it { is_expected.to contain_l23network__l3__ifconfig('ib2.8001') }
    it { is_expected.to contain_l23network__l3__ifconfig('ib2.8001').with({
        'ipaddr' => '192.168.101.3/24',
    })}
    it { is_expected.to contain_l23_stored_config('ib2.8001').with({
        'vlan_dev'  => nil,
        'vlan_id'   => nil,
        'vlan_mode' => nil
    })}
  end

  context 'network scheme with IB device, listed into interfaces and endpoints sections only' do
    let(:title) { 'empty network scheme' }
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
            ib2.8001: {}
          transformations: []
          endpoints:
            ib2.8001:
              IP:
                - 192.168.101.3/24
          roles: {}
      '''
    }}

    before(:each) do
      puppet_debug_override()
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_l23network__l2__port('ib2.8001') }
    it { is_expected.to contain_l23network__l2__port('ib2.8001').with({
        'vlan_dev'  => false,
        'vlan_id'   => nil
    })}
    it { is_expected.to contain_l2_port('ib2.8001') }
    it { is_expected.to contain_l2_port('ib2.8001').with({
        'vlan_dev'  => nil,
        'vlan_id'   => nil
    })}
    it { is_expected.to contain_l23network__l3__ifconfig('ib2.8001') }
    it { is_expected.to contain_l23network__l3__ifconfig('ib2.8001').with({
        'ipaddr' => '192.168.101.3/24',
    })}
    it { is_expected.to contain_l23_stored_config('ib2.8001').with({
        'vlan_dev'  => nil,
        'vlan_id'   => nil,
        'vlan_mode' => nil
    })}
  end

end

###
