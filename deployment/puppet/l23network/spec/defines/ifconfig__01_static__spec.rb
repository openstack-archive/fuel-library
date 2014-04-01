# require 'puppet'
# require 'rspec'
require 'rspec-puppet'
require 'spec_helper'
require 'puppetlabs_spec_helper/puppetlabs_spec/puppet_internals'

# Ubintu, static
describe 'l23network::l3::ifconfig', :type => :define do
  let(:module_path) { '../' }
  let(:title) { 'ifconfig simple test' }
  let(:params) { {
    :interface => 'eth4',
    :ipaddr => '1.2.3.4/16'
  } }
  let(:facts) { {
    :osfamily => 'Debian',
    :operatingsystem => 'Ubuntu',
    :kernel => 'Linux'
  } }
  let(:interface_file_start) { '/etc/network/interfaces.d/ifcfg-' }

  it "Ubintu/static: Should contain interface_file" do
    should contain_file('/etc/network/interfaces').with_content(/\*/)
  end

  it 'Ubintu/static: interface file should contain ipaddr and netmask' do
    rv = contain_file("#{interface_file_start}#{params[:interface]}")
    should rv.with_content(/auto\s+#{params[:interface]}/)
    should rv.with_content(/iface\s+#{params[:interface]}\s+inet\s+static/)
  end

  it 'Ubintu/static: interface file should contain ipaddr and netmask' do
    rv = contain_file("#{interface_file_start}#{params[:interface]}")
    should rv.with_content(/address\s+1.2.3.4/)
    should rv.with_content(/netmask\s+255.255.0.0/)
  end

  it "Ubintu/static: interface file shouldn't contain bond-master options" do
    rv = contain_file("#{interface_file_start}#{params[:interface]}")
    should rv.without_content(/bond-mode/)
    should rv.without_content(/slaves/)
  end
end

# Ubintu, static, netmask as additional parameter
describe 'l23network::l3::ifconfig', :type => :define do
  let(:module_path) { '../' }
  let(:title) { 'ifconfig simple test' }
  let(:params) { {
    :interface => 'eth4',
    :ipaddr => '1.2.3.4',
    :netmask => '255.255.0.0'
  } }
  let(:facts) { {
    :osfamily => 'Debian',
    :operatingsystem => 'Ubuntu',
    :kernel => 'Linux'
  } }
  let(:interface_file_start) { '/etc/network/interfaces.d/ifcfg-' }

  it "Ubintu/static: old.netmask: Should contains interface_file" do
    should contain_file('/etc/network/interfaces').with_content(/\*/)
  end

  it 'Ubintu/static: old.netmask: interface file should contains true header' do
    rv = contain_file("#{interface_file_start}#{params[:interface]}")
    should rv.with_content(/auto\s+#{params[:interface]}/)
    should rv.with_content(/iface\s+#{params[:interface]}\s+inet\s+static/)
  end

  it 'Ubintu/static: old.netmask: interface file should contains ipaddr and netmask' do
    rv = contain_file("#{interface_file_start}#{params[:interface]}")
    should rv.with_content(/address\s+#{params[:ipaddr]}/)
    should rv.with_content(/netmask\s+#{params[:netmask]}/)
  end

  it "Ubintu/static: old.netmask: interface file shouldn't contains bond-master options" do
    rv = contain_file("#{interface_file_start}#{params[:interface]}")
    should rv.without_content(/bond-mode/)
    should rv.without_content(/slaves/)
  end
end

# Ubintu, static, ordered iface
describe 'l23network::l3::ifconfig', :type => :define do
  let(:module_path) { '../' }
  let(:title) { 'ifconfig simple test' }
  let(:params) { {
    :interface => 'eth4',
    :ipaddr => '1.2.3.4/16',
    :ifname_order_prefix => 'zzz'
  } }
  let(:facts) { {
    :osfamily => 'Debian',
    :operatingsystem => 'Ubuntu',
    :kernel => 'Linux'
  } }
  let(:interface_file_start) { '/etc/network/interfaces.d/ifcfg-' }

  it "Ubintu/static: ordered.ifaces: Should contain interface_file" do
    should contain_file('/etc/network/interfaces').with_content(/\*/)
  end

  it 'Ubintu/static: ordered.ifaces: interface file should contain ipaddr and netmask' do
    rv = contain_file("#{interface_file_start}#{params[:ifname_order_prefix]}-#{params[:interface]}")
    should rv.with_content(/auto\s+#{params[:interface]}/)
    should rv.with_content(/iface\s+#{params[:interface]}\s+inet\s+static/)
  end

  it 'Ubintu/static: ordered.ifaces: interface file should contain ipaddr and netmask' do
    rv = contain_file("#{interface_file_start}#{params[:ifname_order_prefix]}-#{params[:interface]}")
    should rv.with_content(/address\s+1.2.3.4/)
    should rv.with_content(/netmask\s+255.255.0.0/)
  end
end



# Centos, static
describe 'l23network::l3::ifconfig', :type => :define do
  let(:module_path) { '../' }
  let(:title) { 'ifconfig simple test' }
  let(:params) { {
    :interface => 'eth4',
    :ipaddr => '1.2.3.4/16'
  } }
  let(:facts) { {
    :osfamily => 'RedHat',
    :operatingsystem => 'Centos',
    :kernel => 'Linux'
  } }
  let(:interface_file_start) { '/etc/sysconfig/network-scripts/ifcfg-' }
  let(:interface_up_file_start) { '/etc/sysconfig/network-scripts/interface-up-script-' }

  it 'Centos/static: interface file should contains true header' do
    rv = contain_file("#{interface_file_start}#{params[:interface]}")
    should rv.with_content(/DEVICE=#{params[:interface]}/)
    should rv.with_content(/BOOTPROTO=none/)
    should rv.with_content(/ONBOOT=yes/)
  end

  it 'Centos/static: Should contains interface_file with IP-addr' do
    rv = contain_file("#{interface_file_start}#{params[:interface]}")
    should rv.with_content(/IPADDR=1.2.3.4/)
    should rv.with_content(/NETMASK=255.255.0.0/)
  end

end

# Centos, static, netmask as additional parameter
describe 'l23network::l3::ifconfig', :type => :define do
  let(:module_path) { '../' }
  let(:title) { 'ifconfig simple test' }
  let(:params) { {
    :interface => 'eth4',
    :ipaddr => '1.2.3.4',
    :netmask => '255.255.0.0'
  } }
  let(:facts) { {
    :osfamily => 'RedHat',
    :operatingsystem => 'Centos',
    :kernel => 'Linux'
  } }
  let(:interface_file_start) { '/etc/sysconfig/network-scripts/ifcfg-' }
  let(:interface_up_file_start) { '/etc/sysconfig/network-scripts/interface-up-script-' }

  it 'Centos/static: old.netmask: interface file should contains true header' do
    rv = contain_file("#{interface_file_start}#{params[:interface]}")
    should rv.with_content(/DEVICE=#{params[:interface]}/)
    should rv.with_content(/BOOTPROTO=none/)
    should rv.with_content(/ONBOOT=yes/)
  end

  it 'Centos/static: old.netmask: Should contains interface_file with IP-addr' do
    rv = contain_file("#{interface_file_start}#{params[:interface]}")
    should rv.with_content(/IPADDR=#{params[:ipaddr]}/)
    should rv.with_content(/NETMASK=#{params[:netmask]}/)
  end
end

# Centos, static, ordered iface
describe 'l23network::l3::ifconfig', :type => :define do
  let(:module_path) { '../' }
  let(:title) { 'ifconfig simple test' }
  let(:params) { {
    :interface => 'eth4',
    :ipaddr => '1.2.3.4/16',
    :ifname_order_prefix => 'zzz'
  } }
  let(:facts) { {
    :osfamily => 'RedHat',
    :operatingsystem => 'Centos',
    :kernel => 'Linux'
  } }
  let(:interface_file_start) { '/etc/sysconfig/network-scripts/ifcfg-' }
  let(:interface_up_file_start) { '/etc/sysconfig/network-scripts/interface-up-script-' }

  it 'Centos/static: ordered.ifaces: interface file should contains true header' do
    rv = contain_file("#{interface_file_start}#{params[:ifname_order_prefix]}-#{params[:interface]}")
    should rv.with_content(/DEVICE=#{params[:interface]}/)
    should rv.with_content(/BOOTPROTO=none/)
    should rv.with_content(/ONBOOT=yes/)
  end

  it 'Centos/static: ordered.ifaces: Should contains interface_file with IP-addr' do
    rv = contain_file("#{interface_file_start}#{params[:ifname_order_prefix]}-#{params[:interface]}")
    should rv.with_content(/IPADDR=1.2.3.4/)
    should rv.with_content(/NETMASK=255.255.0.0/)
  end

end