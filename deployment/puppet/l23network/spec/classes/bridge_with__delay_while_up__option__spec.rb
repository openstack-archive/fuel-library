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
    eth2: {}
    eth3: {}
  transformations:
    - action: add-br
      name: br1
      delay_while_up: 25
    - action: add-br
      name: br2
  endpoints: {}
  roles: {}
eof
end

  context 'Centos should contain addition file for handle "delay_while_up" property.' do
    let(:title) { 'Centos has delay for port after boot' }
    let(:facts) {
      {
        :osfamily => 'RedHat',
        :operatingsystem => 'Centos',
        :kernel => 'Linux',
        :l23_os => 'centos6',
        :l3_fqdn_hostname => 'stupid_hostname',
      }
    }

    let(:params) do {
      :settings_yaml => network_scheme,
    } end

    it do
      should compile.with_all_deps
    end

    it do
      should contain_l23_stored_config('br1').with({
        'delay_while_up'  => '25',
      })
    end

    it do
      should contain_file('/etc/sysconfig/network-scripts/interface-up-script-br1').with_owner('root')
    end

    it do
      should contain_file('/etc/sysconfig/network-scripts/interface-up-script-br1').with_mode('0755')
    end

    it do
      should contain_file('/etc/sysconfig/network-scripts/interface-up-script-br1').with_content(/sleep\s+25/)
    end

    it do
      should contain_l23_stored_config('br2').with({
        'delay_while_up'  => nil,
      })
    end

  end

  context 'Property "delay_while_up" for port' do
    let(:title) { 'Property "delay_while_up" for port' }
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

    it do
      should compile.with_all_deps
    end

    it do
      should contain_l23_stored_config('br1').with({
        'delay_while_up'  => '25',
      })
    end

    it do
      should contain_l23_stored_config('br2').with({
        'delay_while_up'  => nil,
      })
    end

  end

end

###
