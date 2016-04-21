require 'spec_helper'

describe 'l23network::examples::run_network_scheme', :type => :class do
let(:network_scheme) do
<<eof
---
network_scheme:
  version: 1.1
  provider: lnx
  interfaces:
    eth2: {}
    eth3: {}
  transformations:
    - action: add-port
      name:   eth2.102
    - action: add-port
      name:   eth3.103
  endpoints:
    eth2.102:
      IP:
        - 192.168.101.3/24
    eth3.103:
      IP:
        - 192.168.101.3/24
  roles: {}
eof
end
  context 'with transformations and endpoint for subinterfaces' do
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

    before(:each) do
      puppet_debug_override()
    end

    let(:params) do {
      :settings_yaml => network_scheme,
    } end

    it do
      should compile.with_all_deps
    end

    it do
      should contain_L23network__L2__Port('eth2')
    end

    it do
      should contain_L23network__L2__Port('eth2.102')
    end
    it do
      should contain_L23network__L2__Port('eth2.102').that_requires('L23network::L2::Port[eth2]')
    end

    it do
      should contain_L23network__L3__Ifconfig('eth2.102')
    end
    it do
      should contain_L23network__L3__Ifconfig('eth2.102').that_requires('L23network::L2::Port[eth2.102]')
    end

    it do
      should contain_L23network__L2__Port('eth3')
    end

    it do
      should contain_L23network__L2__Port('eth3.103')
    end
    it do
      should contain_L23network__L2__Port('eth3.103').that_requires("L23network::L2::Port[eth3]")
    end

    it do
      should contain_L23network__L3__Ifconfig('eth3.103')
    end
    it do
      should contain_L23network__L3__Ifconfig('eth3.103').that_requires("L23network::L2::Port[eth3.103]")
    end

    it do
      should contain_disable_hotplug('global')
    end

    it do
      should contain_enable_hotplug('global').that_requires('L23_stored_config[eth3.103]')
    end

  end
end

describe 'l23network::examples::run_network_scheme', :type => :class do
let(:network_scheme) do
<<eof
---
network_scheme:
  version: 1.1
  provider: lnx
  interfaces:
    eth2: {}
    eth3: {}
  transformations:
    - action: add-bond
      name:   bond0
      interfaces:
        - eth2
        - eth3
      bridge: br-bond0
      bond_properties:
        mode: balance-rr
  endpoints:
    bond0:
      IP:
        - 192.168.101.3/24
  roles: {}
eof
end

  context 'with transformations and endpoint for bond' do
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

    before(:each) do
      puppet_debug_override()
    end

    let(:params) do {
      :settings_yaml => network_scheme,
    } end

    it do
      should compile.with_all_deps
    end

    it do
      should contain_L23network__L2__Bond_interface('eth2')
    end
    it do
      should contain_L23network__L2__Port('eth2')
    end

    it do
      should contain_L23network__L2__Bond_interface('eth3')
    end
    it do
      should contain_L23network__L2__Port('eth3')
    end

    it do
      should contain_L23network__L2__Bond('bond0')
    end
    it do
      should contain_L2_bond('bond0').that_requires('L2_port[eth2]')
    end
    it do
      should contain_L2_bond('bond0').that_requires('L2_port[eth3]')
    end

    it do
      should contain_L23network__L3__Ifconfig('bond0')
    end
    it do
      should contain_L23network__L3__Ifconfig('bond0').that_requires("L23network::L2::Bond[bond0]")
    end

  end
end

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
      name: br-eth1
    - action: add-port
      bridge: br-eth1
      name: eth1
    - action: add-br
      name: br-eth2
      provider: ovs
    - action: add-port
      bridge: br-eth2
      name: eth2
      provider: lnx
    - action: add-br
      name: br-eth3
      provider: ovs
    - action: add-port
      bridge: br-eth3
      name: eth3
  endpoints:
    br-eth3:
      IP:
        - 192.168.101.3/24
  roles: {}
eof
end

  context 'with transformations and endpoint for bridge' do
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

    before(:each) do
      puppet_debug_override()
    end

    let(:params) do {
      :settings_yaml => network_scheme,
    } end

    it do
      should compile.with_all_deps
    end

    it do
      should contain_L23network__L2__Bridge('br-eth1')
    end
    it do
      should contain_L23network__L2__Port('eth1').with({
        :bridge => 'br-eth1',
        :provider => 'lnx'})
    end

    it do
      should contain_L23network__L2__Bridge('br-eth2')
    end
    it do
      should contain_L23network__L2__Port('eth2').with({
        :bridge => 'br-eth2',
        :provider => 'lnx'})
    end

    it do
      should contain_L23network__L2__Bridge('br-eth3')
    end
    it do
      should contain_L23network__L2__Port('eth3').with({
        :bridge => 'br-eth3',
        :provider => 'ovs'})
    end
    #it do
    #  should contain_L2_bridge('br-eth3').that_requires('L2_port[eth3]')
    #end

    it do
      should contain_L23network__L3__Ifconfig('br-eth3')
    end
    it do
      should contain_L23network__L3__Ifconfig('br-eth3').that_requires("L23network::L2::Bridge[br-eth3]")
    end

  end
end
# vim: set ts=2 sw=2 et :
