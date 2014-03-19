# require 'puppet'
# require 'rspec'
require 'rspec-puppet'
require 'spec_helper'
require 'puppetlabs_spec_helper/puppetlabs_spec/puppet_internals'

# Ubintu, manual -- no IP addresses, but interface in UP state
describe 'l23network::l3::ifconfig', :type => :define do
  let(:module_path) { '../' }
  let(:title) { 'ifconfig simple test' }
  let(:params) { {
    :interface => 'eth4',
    :ipaddr => 'none'
  } }
  let(:facts) { {
    :osfamily => 'Debian',
    :operatingsystem => 'Ubuntu',
    :kernel => 'Linux'
  } }
  let(:interface_file_start) { '/etc/network/interfaces.d/ifcfg-' }

  it "Should contain interface_file" do
    should contain_file('/etc/network/interfaces').with_content(/\*/)
  end

  it 'interface file should contain DHCP ipaddr and netmask' do
    rv = contain_file("#{interface_file_start}#{params[:interface]}")
    should rv.with_content(/auto\s+#{params[:interface]}/)
    should rv.with_content(/iface\s+#{params[:interface]}\s+inet\s+manual/)
  end

  it "interface file shouldn't contain ipaddr and netmask" do
    rv = contain_file("#{interface_file_start}#{params[:interface]}")
    should rv.without_content(/address/)
    should rv.without_content(/netmask/)
  end

  it "interface file should contain ifup/ifdn commands" do
    rv = contain_file("#{interface_file_start}#{params[:interface]}")
    should rv.with_content(/up\s+ip\s+l\s+set\s+#{params[:interface]}\s+up/)
    should rv.with_content(/down\s+ip\s+l\s+set\s+#{params[:interface]}\s+down/)
  end
end

# Ubintu, static, ordered iface
describe 'l23network::l3::ifconfig', :type => :define do
  let(:module_path) { '../' }
  let(:title) { 'ifconfig simple test' }
  let(:params) { {
    :interface => 'eth4',
    :ipaddr => 'none',
    :ifname_order_prefix => 'zzz'
  } }
  let(:facts) { {
    :osfamily => 'Debian',
    :operatingsystem => 'Ubuntu',
    :kernel => 'Linux'
  } }
  let(:interface_file_start) { '/etc/network/interfaces.d/ifcfg-' }

  it "Should contain interface_file" do
    should contain_file('/etc/network/interfaces').with_content(/\*/)
  end

  it "interface file shouldn't contain ipaddr and netmask" do
    rv = contain_file("#{interface_file_start}#{params[:ifname_order_prefix]}-#{params[:interface]}")
    should rv.without_content(/address/)
    should rv.without_content(/netmask/)
  end

  it "interface file should contain ifup/ifdn commands" do
    rv = contain_file("#{interface_file_start}#{params[:ifname_order_prefix]}-#{params[:interface]}")
    should rv.with_content(/up\s+ip\s+l\s+set\s+#{params[:interface]}\s+up/)
    should rv.with_content(/down\s+ip\s+l\s+set\s+#{params[:interface]}\s+down/)
  end
end



# Centos, manual -- no IP addresses, but interface in UP state
describe 'l23network::l3::ifconfig', :type => :define do
  let(:module_path) { '../' }
  let(:title) { 'ifconfig simple test' }
  let(:params) { {
    :interface => 'eth4',
    :ipaddr => 'none'
  } }
  let(:facts) { {
    :osfamily => 'RedHat',
    :operatingsystem => 'Centos',
    :kernel => 'Linux'
  } }
  let(:interface_file_start) { '/etc/sysconfig/network-scripts/ifcfg-' }
  let(:interface_up_file_start) { '/etc/sysconfig/network-scripts/interface-up-script-' }

  it 'interface file should contains true header' do
    rv = contain_file("#{interface_file_start}#{params[:interface]}")
    should rv.with_content(/DEVICE=#{params[:interface]}/)
    should rv.with_content(/BOOTPROTO=none/)
    should rv.with_content(/ONBOOT=yes/)
  end

  it "Shouldn't contains interface_file with IP-addr" do
    rv = contain_file("#{interface_file_start}#{params[:interface]}")
    should rv.without_content(/IPADDR=/)
    should rv.without_content(/NETMASK=/)
  end
end

# Centos, manual, ordered iface
describe 'l23network::l3::ifconfig', :type => :define do
  let(:module_path) { '../' }
  let(:title) { 'ifconfig simple test' }
  let(:params) { {
    :interface => 'eth4',
    :ipaddr => 'none',
    :ifname_order_prefix => 'zzz'
  } }
  let(:facts) { {
    :osfamily => 'RedHat',
    :operatingsystem => 'Centos',
    :kernel => 'Linux'
  } }
  let(:interface_file_start) { '/etc/sysconfig/network-scripts/ifcfg-' }
  let(:interface_up_file_start) { '/etc/sysconfig/network-scripts/interface-up-script-' }

  it 'interface file should contains true header' do
    rv = contain_file("#{interface_file_start}#{params[:ifname_order_prefix]}-#{params[:interface]}")
    should rv.with_content(/DEVICE=#{params[:interface]}/)
    should rv.with_content(/BOOTPROTO=none/)
    should rv.with_content(/ONBOOT=yes/)
  end

  it 'Should contains interface_file with IP-addr' do
    rv = contain_file("#{interface_file_start}#{params[:ifname_order_prefix]}-#{params[:interface]}")
    should rv.without_content(/IPADDR=/)
    should rv.without_content(/NETMASK=/)
  end

end

###