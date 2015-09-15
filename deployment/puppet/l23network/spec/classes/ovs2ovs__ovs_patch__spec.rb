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
      name: br-ovs2
      provider: ovs
    - action: add-br
      name: br-ovs1
      provider: ovs
    - action: add-patch
      bridges:
        - br-ovs2
        - br-ovs1
      provider: ovs
  endpoints: {}
  roles: {}
eof
end

  context 'Patch between two OVS bridges.' do
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

    get_provider_for = {}
    before(:each) do
      if ENV['SPEC_PUPPET_DEBUG']
        Puppet::Util::Log.level = :debug
        Puppet::Util::Log.newdestination(:console)
      end

      Puppet::Parser::Functions.newfunction(:get_provider_for, :type => :rvalue) {
        |args| get_provider_for.call(args[0], args[1])
      }

      get_provider_for.stubs(:call).with('L2_bridge', 'br-ovs1').returns('ovs')
      get_provider_for.stubs(:call).with('L2_bridge', 'br-ovs2').returns('ovs')
    end

    it do
      should compile.with_all_deps
    end

    it do
      should contain_l23_stored_config('br-ovs1').with({
        'ensure'   => 'present',
        'provider' => 'ovs_ubuntu'
      })
    end

    it do
      should contain_l23_stored_config('br-ovs2').with({
        'ensure'   => 'present',
        'provider' => 'ovs_ubuntu'
      })
    end

    it do
      should contain_l2_bridge('br-ovs1').with({
        'ensure'   => 'present',
        'provider' => 'ovs'
      })
    end

    it do
      should contain_l2_bridge('br-ovs2').with({
        'ensure'   => 'present',
        'provider' => 'ovs'
      })
    end

    it do
      should contain_l2_patch('patch__br-ovs1--br-ovs2').with({
        'ensure'   => 'present',
        'bridges'  => ['br-ovs1', 'br-ovs2'],
        'vlan_ids' => ['0', '0'],
        'provider' => 'ovs'
      })
    end

    it do
      should contain_l2_patch('patch__br-ovs1--br-ovs2').with_jacks(['p_f277dc2b-0', 'p_f277dc2b-1'])
    end

    it do
      should_not contain_l23_stored_config('p_f277dc2b-0')
    end
  end

end

# vim: set ts=2 sw=2 et
