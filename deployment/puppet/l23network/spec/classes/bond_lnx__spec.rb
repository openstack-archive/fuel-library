# require 'puppet'
# require 'rspec'
require 'rspec-puppet'
require 'spec_helper'
require 'puppetlabs_spec_helper/puppetlabs_spec/puppet_internals'

# Ubintu, static
describe 'l23network::examples::bond_lnx', :type => :class do
  let(:module_path) { '../' }
  #let(:title) { 'bond0' }
  let(:params) { {
    :bond       => 'bond0',
    :ipaddr     => '1.1.1.1/27',
    :interfaces => ['eth4','eth5']
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

  it 'Should contains interface files for bond-slave interfaces' do
    params[:interfaces].each do |iface|
      rv = contain_file("#{interface_file_start}#{iface}")
      should rv.with_content(/auto\s+#{iface}/)
      should rv.with_content(/iface\s+#{iface}/)
      should rv.with_content(/bond-master\s+#{params[:bond]}/)
    end
  end

end

# # Centos, static
# describe 'l23network::l3::ifconfig', :type => :define do
#   let(:module_path) { '../' }
#   let(:title) { 'eth4' }
#   let(:params) { {
#     :ipaddr => ['1.1.1.1/16','2.2.2.2/25','3.3.3.3/26']
#   } }
#   let(:facts) { {
#     :osfamily => 'RedHat',
#     :operatingsystem => 'Centos',
#     :kernel => 'Linux'
#   } }
#   let(:interface_file) { '/etc/sysconfig/network-scripts/ifcfg-eth4' }
#   let(:interface_up_file) { '/etc/sysconfig/network-scripts/interface-up-script-eth4' }

#   it 'Should contain interface_file /etc/sysconfig/network-scripts/ifcfg-eth4' do
#     rv = contain_file("#{interface_file}")
#     should rv.with_content(/DEVICE=#{title}/)
#     should rv.with_content(/BOOTPROTO=none/)
#     should rv.with_content(/ONBOOT=yes/)
#   end

#   it 'Should contains common ifup script file /sbin/ifup-local' do
#     should contain_file("/sbin/ifup-local")
#   end

#   it 'Should contain main ipaddr' do
#     rv = contain_file("#{interface_file}")
#     should rv.with_content(/IPADDR=1.1.1.1/)
#     should rv.with_content(/NETMASK=255.255.0.0/)
#   end

#   it 'Should contains post-up directives for apply IP aliases' do
#     rv = contain_file("#{interface_up_file}")
#     params[:ipaddr][1..-1].each do |addr|
#       should rv.with_content(/ip\s+addr\s+add\s+#{addr}\s+dev\s+#{title}/)
#     end
#   end

# end
