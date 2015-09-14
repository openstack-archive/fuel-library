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
      expect {
        # This wrapper prevent us from false positives result. This safe equalent the 'should not contain' condition.
        should contain_l23_stored_config('p_f277dc2b-0')
      }.to raise_error(RSpec::Expectations::ExpectationNotMetError, /catalogue\s+would\s+contain\s+L23_stored_config\[p_f277dc2b-0\]/)\
    end
  end

end

###
