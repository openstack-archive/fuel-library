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
      if ENV['SPEC_PUPPET_DEBUG']
        Puppet::Util::Log.level = :debug
        Puppet::Util::Log.newdestination(:console)
      end
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
      if ENV['SPEC_PUPPET_DEBUG']
        Puppet::Util::Log.level = :debug
        Puppet::Util::Log.newdestination(:console)
      end
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
    eth2: {}
    eth3: {}
  transformations:
    - action: add-bond
      name:   bond0
      interfaces:
        - eth2
        - eth3
      bridge: some-bridge
      bond_properties:
        mode: balance-rr
      provider: ovs
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
      if ENV['SPEC_PUPPET_DEBUG']
        Puppet::Util::Log.level = :debug
        Puppet::Util::Log.newdestination(:console)
      end
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

# vim: set ts=2 sw=2 et :
require 'spec_helper'

describe 'l23network::examples::run_network_scheme', :type => :class do
let(:network_scheme) do
<<eof
---
network_scheme:
  version: 1.1
  provider: lnx
  transformations:
  - action: add-br
    name: br-ex
  - action: add-br
    name: br-floating
    provider: ovs
  - action: add-patch
    bridges:
    - br-floating
    - br-ex
    mtu: 9000
    provider: ovs
  - action: add-port
    bridge: br-ex
    name: eth0
  - action: add-br
    name: br-prv
    provider: ovs
  - action: add-br
    name: br-aux
  - action: add-patch
    bridges:
    - br-prv
    - br-aux
    mtu: 9000
    provider: ovs
  - action: add-port
    bridge: br-aux
    name: eth3
  - action: add-br
    name: br-storage
  - action: add-port
    bridge: br-storage
    name: eth2.141
  - action: add-br
    name: br-fw-admin
  - action: add-port
    bridge: br-fw-admin
    name: eth2
  - action: add-br
    name: br-mgmt
  - action: add-port
    bridge: br-mgmt
    name: eth2.140
  interfaces:
    eth3:
      vendor_specific:
        driver: ixgbe
        bus_info: '0000:05:00.1'
    eth2:
      vendor_specific:
        driver: ixgbe
        bus_info: '0000:05:00.0'
    eth1:
      vendor_specific:
        driver: igb
        bus_info: '0000:03:00.1'
    eth0:
      vendor_specific:
        driver: igb
        bus_info: '0000:03:00.0'
  endpoints:
    br-prv:
      IP: none
    br-fw-admin:
      IP:
      - 10.20.0.3/16
    br-floating:
      IP: none
    br-storage:
      IP:
      - 192.168.1.1/24
    br-mgmt:
      IP:
      - 192.168.0.3/24
    br-ex:
      IP:
      - 172.16.47.233/22
      gateway: 172.16.44.1
  roles: {}

eof
end
  context 'bridge transformations should be first' do
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
      if ENV['SPEC_PUPPET_DEBUG']
        Puppet::Util::Log.level = :debug
        Puppet::Util::Log.newdestination(:console)
      end
    end

    let(:params) do {
      :settings_yaml => network_scheme,
    } end

    it do
      should compile.with_all_deps
    end

    it do
      should_not contain_L23network__L2__Bridge('br-fw-admin').that_requires('L23network::L2::Port[eth2.141]')
    end

    it do
      should contain_L23network__L2__Bridge('br-fw-admin').that_requires('L23network::L3::Ifconfig[br-storage]')
    end

  end
end

# vim: set ts=2 sw=2 et :
