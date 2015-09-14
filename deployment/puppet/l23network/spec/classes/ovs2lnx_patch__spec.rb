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
      delay_while_up: 25
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

    it do
      should compile.with_all_deps
    end

    it do
      should contain_l23_stored_config('br-ovs').with({
      })
    end

    it do
      should contain_l23_stored_config('br1').with({
      })
    end

  end

end

###
