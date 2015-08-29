require 'spec_helper'

describe 'l23network::examples::run_network_scheme', :type => :class do
let(:network_scheme) do
<<eof
---
network_scheme:
  version: 1.1
  provider: lnx
  interfaces:
    eth1:
      mtu: 1200
    eth2: {}
    eth3: {}
    eth4: {}
  transformations:
    - action: add-br
      name: br1
    - action: add-port
      name:   eth1.101
      bridge: br1
    - action: add-bond
      name:   bond0
      mtu:    9000
      interfaces:
        - eth2
        - eth3
      bond_properties:
        mode: balance-rr
    - action: add-port
      name: bond0.201
    - action: add-br
      name: br4
    - action: add-port
      name:   eth4.401
      bridge: br4
    - action: add-br
      name: br10
  endpoints: {}
  roles: {}
eof
end

  context 'Find phys_dev for each transformation and adjust MTU by them' do
    let(:title) { 'Find phys_dev for each transformation and adjust MTU by them' }
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

    it { should contain_l2_port('eth1') }
    it { should contain_l2_port('eth2') }
    it { should contain_l2_port('eth3') }
    it { should contain_l2_port('eth4') }

    it { should contain_l2_port('eth1').with({ 'mtu' => '1200' }) }
    it { should contain_l2_port('eth2').with({ 'mtu' => '9000' }) }
    it { should contain_l2_port('eth3').with({ 'mtu' => '9000' }) }
    it { should contain_l2_port('eth4').without('mtu') }

    it { should contain_l2_bond('bond0').with({ 'mtu' => '9000' }) }
    it { should contain_l2_port('bond0.201').with({ 'mtu' => '9000' }) }

    it { should contain_l2_bridge('br10').without('mtu') }

    it { should contain_l2_port('eth1.101').with({ 'mtu' => '1200' }) }
    it { should contain_l2_port('eth4.401').without('mtu') }


  end

end

###
