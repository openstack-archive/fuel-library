require 'rspec-puppet'
require 'spec_helper'
require 'puppetlabs_spec_helper/puppetlabs_spec/puppet_internals'
require 'yaml'

#fuel_settings = YAML::load(<<-EOM)
c_ipaddr = '10.0.0.1'
c_masklen = '24'
c_mode = 2
c_bondname = 'bond0'
c_interfaces = ['eth1','eth2']
c_lacp_rate = 2
c_miimon = 150
bond_modes = [
    'balance-rr',
    'active-backup',
    'balance-xor',
    'broadcast',
    '802.3ad',
    'balance-tlb',
    'balance-alb'
]
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
  transformations:
    - action: add-br
      name: br-#{c_bondname}
    - action: add-bond
      bridge: br-#{c_bondname}
      name: #{c_bondname}
      provider: lnx
      interfaces:
        - eth1
        - eth2
      properties:
        mode: #{c_mode}
        miimon: #{c_miimon}
        lacp_rate: #{c_lacp_rate}
  endpoints:
    #{c_bondname}:
      IP:
       - #{c_ipaddr}/#{c_masklen}
    # eth1:
    #   IP: none
    # eth2:
    #   IP: none
EOM

#p fuel_settings

# Ubintu, static
describe 'l23network::examples::adv_net_config__bond_lnx', :type => :class do
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

  it "Should contains interface_file" do
    should contain_file('/etc/network/interfaces').with_content(/\*/)
  end

  it 'Should contains interface_file with IP-addr' do
    rv = contain_file("#{interface_file_start}#{c_bondname}")
    should rv.with_content(/auto\s+#{c_bondname}/)
    should rv.with_content(/iface\s+#{c_bondname}/)
    should rv.with_content(/address\s+#{c_ipaddr}/)
    should rv.with_content(/netmask\s+255.255.255.0/)
  end

  it 'Should contains bond-specific parameters' do
    rv = contain_file("#{interface_file_start}#{c_bondname}")
    should rv.with_content(/slaves\s+none/)
    should rv.with_content(/bond-mode\s+#{c_mode}/)
    should rv.with_content(/bond-miimon\s+#{c_miimon}/)
    should rv.with_content(/bond-lacp-rate\s+#{c_lacp_rate}/)
  end

  it 'Should contains interface files for bond-slave interfaces' do
    c_interfaces.each do |iface|
      rv = contain_file("#{interface_file_start}#{iface}")
      should rv.with_content(/auto\s+#{iface}/)
      should rv.with_content(/iface\s+#{iface}/)
      should rv.with_content(/bond-master\s+#{c_bondname}/)
    end
  end

  it 'ALL: Should contains l23network::l2::bridge resource' do
      rv = contain_l23network__l2__bridge("br-#{c_bondname}")
      should rv.with(
        'ensure'     => 'present'
      )
  end

  it 'ALL: Should contains l23network::l2::port resource' do
      rv = contain_l23network__l2__port("#{c_bondname}")
      should rv.with(
        'bridge'     => "br-#{c_bondname}",
        'ensure'     => 'present'
      )
  end

  it 'ALL: Should contains relationship beetwen l23network::l2::bridge and l23network::l2::port' do
      bridge = contain_l23network__l2__bridge("br-#{c_bondname}")
      should bridge.that_comes_before("L23network::L2::Port[#{c_bondname}]")
  end

end

# Centos, static
describe 'l23network::examples::adv_net_config__bond_lnx', :type => :class do
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
  let(:interface_up_file_start) { '/etc/sysconfig/network-scripts/interface-up-script-' }
  let(:bond_modes) { [
    'balance-rr',
    'active-backup',
    'balance-xor',
    'broadcast',
    '802.3ad',
    'balance-tlb',
    'balance-alb'
  ] }

  it 'Should contains interface_file with IP-addr' do
    rv = contain_file("#{interface_file_start}#{c_bondname}")
    should rv.with_content(/DEVICE=#{c_bondname}/)
    should rv.with_content(/BOOTPROTO=none/)
    should rv.with_content(/ONBOOT=yes/)
    should rv.with_content(/IPADDR=#{c_ipaddr}/)
    should rv.with_content(/NETMASK=255.255.255.0/)
  end

  it 'Should contains interface files for bond-slave interfaces' do
    c_interfaces.each do |iface|
      rv = contain_file("#{interface_file_start}#{iface}")
      should rv.with_content(/DEVICE=#{iface}/)
      should rv.with_content(/BOOTPROTO=none/)
      should rv.with_content(/ONBOOT=yes/)
      should rv.with_content(/MASTER=#{c_bondname}/)
      should rv.with_content(/SLAVE=yes/)
    end
  end

  it 'Should contains Bonding-opts line' do
    rv = contain_file("#{interface_file_start}#{c_bondname}")
    should rv.with_content(/DEVICE=#{c_bondname}/)
    should rv.with_content(/BONDING_OPTS="mode=/)
  end

  it 'Should contains Bond mode' do
    rv = contain_file("#{interface_file_start}#{c_bondname}")
    should rv.with_content(/BONDING_OPTS.*mode=#{bond_modes[c_mode]}/)
  end

  it 'Should contains miimon' do
    rv = contain_file("#{interface_file_start}#{c_bondname}")
    should rv.with_content(/BONDING_OPTS.*miimon=#{c_miimon}/)
  end

  it 'Should contains lacp_rate' do
    rv = contain_file("#{interface_file_start}#{c_bondname}")
    should rv.with_content(/BONDING_OPTS.*lacp_rate=#{c_lacp_rate}/)
  end
end
