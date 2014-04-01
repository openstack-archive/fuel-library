# require 'puppet'
# require 'rspec'
require 'rspec-puppet'
require 'spec_helper'
require 'puppetlabs_spec_helper/puppetlabs_spec/puppet_internals'

# Ubintu, static
describe 'l23network::examples::bond_lnx_old_style', :type => :class do
  let(:module_path) { '../' }
  #let(:title) { 'bond0' }
  let(:params) { {
    :bond       => 'bond0',
    :ipaddr     => '1.1.1.1/27',
    :interfaces => ['eth4','eth5'],
    :bond_mode       => 2,
    :bond_miimon     => 200,
    :bond_lacp_rate  => 2,
  } }
  let(:facts) { {
    :osfamily => 'Debian',
    :operatingsystem => 'Ubuntu',
    :kernel => 'Linux'
  } }
  let(:interface_file_start) { '/etc/network/interfaces.d/ifcfg-' }

  it "Should contains interface_file" do
    should contain_file('/etc/network/interfaces').with_content(/\*/)
  end

  it 'Should contains interface_file with IP-addr' do
    rv = contain_file("#{interface_file_start}#{params[:bond]}")
    should rv.with_content(/auto\s+#{params[:bond]}/)
    should rv.with_content(/iface\s+#{params[:bond]}/)
    should rv.with_content(/address\s+1.1.1.1/)
    should rv.with_content(/netmask\s+255.255.255.224/)
  end

  it 'Should contains bond-specific parameters' do
    rv = contain_file("#{interface_file_start}#{params[:bond]}")
    should rv.with_content(/slaves\s+none/)
    should rv.with_content(/bond-mode\s+#{params[:bond_mode]}/)
    should rv.with_content(/bond-miimon\s+#{params[:bond_miimon]}/)
    should rv.with_content(/bond-lacp-rate\s+#{params[:bond_lacp_rate]}/)
  end

  it 'Should contains interface files for bond-slave interfaces' do
    params[:interfaces].each do |iface|
      rv = contain_file("#{interface_file_start}#{iface}")
      should rv.with_content(/auto\s+#{iface}/)
      should rv.with_content(/iface\s+#{iface}/)
      should rv.with_content(/bond-master\s+#{params[:bond]}/)
    end
  end

end

# Centos, static
describe 'l23network::examples::bond_lnx_old_style', :type => :class do
  let(:module_path) { '../' }
  #let(:title) { 'bond0' }
  let(:params) { {
    :bond       => 'bond0',
    :ipaddr     => '1.1.1.1/27',
    :interfaces => ['eth4','eth5'],
    :bond_mode       => 2,
    :bond_miimon     => 200,
    :bond_lacp_rate  => 0,
  } }
  let(:facts) { {
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
    rv = contain_file("#{interface_file_start}#{params[:bond]}")
    should rv.with_content(/DEVICE=#{params[:bond]}/)
    should rv.with_content(/BOOTPROTO=none/)
    should rv.with_content(/ONBOOT=yes/)
    should rv.with_content(/IPADDR=1.1.1.1/)
    should rv.with_content(/NETMASK=255.255.255.224/)
  end

  it 'Should contains interface files for bond-slave interfaces' do
    params[:interfaces].each do |iface|
      rv = contain_file("#{interface_file_start}#{iface}")
      should rv.with_content(/DEVICE=#{iface}/)
      should rv.with_content(/BOOTPROTO=none/)
      should rv.with_content(/ONBOOT=yes/)
      should rv.with_content(/MASTER=#{params[:bond]}/)
      should rv.with_content(/SLAVE=yes/)
    end
  end

  it 'Should contains Bonding-opts line' do
    rv = contain_file("#{interface_file_start}#{params[:bond]}")
    should rv.with_content(/DEVICE=#{params[:bond]}/)
    should rv.with_content(/BONDING_OPTS="mode=/)
  end

  it 'Should contains Bond mode' do
    rv = contain_file("#{interface_file_start}#{params[:bond]}")
    should rv.with_content(/BONDING_OPTS.*mode=#{bond_modes[params[:bond_mode]]}/)
  end

  it 'Should contains miimon' do
    rv = contain_file("#{interface_file_start}#{params[:bond]}")
    should rv.with_content(/BONDING_OPTS.*miimon=#{params[:miimon]}/)
  end

  it 'Should contains lacp_rate' do
    rv = contain_file("#{interface_file_start}#{params[:bond]}")
    should rv.with_content(/BONDING_OPTS.*lacp_rate=#{params[:lacp_rate]}/)
  end
end
