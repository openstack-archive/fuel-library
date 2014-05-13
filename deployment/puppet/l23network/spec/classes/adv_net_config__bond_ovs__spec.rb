require 'rspec-puppet'
require 'spec_helper'
require 'puppetlabs_spec_helper/puppetlabs_spec/puppet_internals'
require 'yaml'

#fuel_settings = YAML::load(<<-EOM)
c_bondname = 'bond0'
c_interfaces = ['eth1','eth2']
c_lacp_rate = 2
c_miimon = 150
fuel_settings = YAML::load(<<-EOM)
network_scheme:
  version: '1.0'
  provider: ovs
  interfaces:
    eth2:
      L2:
        vlan_splinters: 'off'
    eth1:
      L2:
        vlan_splinters: 'off'
    eth5:
      fake:
        interface: eth5
  transformations:
    - action: add-br
      name: br-#{c_bondname}
    - action: add-bond
      bridge: br-#{c_bondname}
      name: #{c_bondname}
      interfaces:
        - eth1
        - eth2
      properties:
      - bond_mode=active-backup
  endpoints:
    eth5:
      IP: none
EOM

# Ubintu
describe 'l23network::examples::adv_net_config__bond_ovs', :type => :class do
  let(:module_path) { '../' }
  #let(:title) { 'bond0' }
  let(:params) { {
    :fuel_settings => fuel_settings
  } }
  let(:facts) { {
    :l3_fqdn_hostname => 'qweqweqwe',
    :osfamily => 'Debian',
    :operatingsystem => 'Ubuntu',
    :kernel => 'Linux'
  } }
  let(:interface_file_start) { '/etc/network/interfaces.d/ifcfg-' }

  it "UBUNTU: Should contains interface_file" do
    should contain_file('/etc/network/interfaces').with_content(/\*/)
  end

  it 'UBUNTU: Should contains interface files for bond-slave interfaces' do
    c_interfaces.each do |iface|
      rv = contain_file("#{interface_file_start}#{iface}")
      should rv.with_content(/auto\s+#{iface}/)
      should rv.with_content(/iface\s+#{iface}/)
      should rv.with_content(/up\s+ip\s+l\s+set\s+#{iface}\s+up/)
      should rv.with_content(/down\s+ip\s+l\s+set\s+#{iface}\s+down/)
    end
  end

  it 'ALL: Should contains l23network::l2::bridge resource' do
      rv = contain_l23network__l2__bridge("br-#{c_bondname}")
      should rv.with(
        'ensure'     => 'present'
      )
  end

  it 'ALL: Should contains l23network::l2::bond resource' do
      rv = contain_l23network__l2__bond("#{c_bondname}")
      should rv.with(
        'bridge'     => "br-#{c_bondname}",
        'interfaces' => c_interfaces,
        'ensure'     => 'present'
      )
  end

  it 'ALL: Should contains relationship beetwen l23network::l2::bridge and l23network::l2::bond' do
      bridge = contain_l23network__l2__bridge("br-#{c_bondname}")
      should bridge.that_comes_before("L23network::L2::Bond[#{c_bondname}]")
  end

end

# Centos
describe 'l23network::examples::adv_net_config__bond_ovs', :type => :class do
  let(:module_path) { '../' }
  #let(:title) { 'bond0' }
  let(:params) { {
    :fuel_settings => fuel_settings
  } }
  let(:facts) { {
    :l3_fqdn_hostname => 'qweqweqwe',
    :osfamily => 'RedHat',
    :operatingsystem => 'Centos',
    :kernel => 'Linux'
  } }
  let(:interface_file_start) { '/etc/sysconfig/network-scripts/ifcfg-' }

  it 'CENTOS: Should contains interface files for bond-slave interfaces' do
    c_interfaces.each do |iface|
      rv = contain_file("#{interface_file_start}#{iface}")
      should rv.with_content(/DEVICE=#{iface}/)
      should rv.with_content(/BOOTPROTO=none/)
      should rv.with_content(/ONBOOT=yes/)
    end
  end

end
