# require 'puppet'
# require 'rspec'
require 'rspec-puppet'
require 'spec_helper'
require 'puppetlabs_spec_helper/puppetlabs_spec/puppet_internals'

# Ubintu, static
describe 'l23network::l3::ifconfig', :type => :define do
  let(:module_path) { '../' }
  let(:title) { 'eth4' }
  let(:params) { {
    :ipaddr => '1.2.3.4/24',
    :macaddr => 'AA:BB:CC:33:22:11'
  } }
  let(:facts) { {
    :osfamily => 'Debian',
    :operatingsystem => 'Ubuntu',
    :kernel => 'Linux'
  } }
  let(:interface_file) { '/etc/network/interfaces.d/ifcfg-eth4' }

  it "Should contain interface_file" do
    should contain_file('/etc/network/interfaces').with_content(/\*/)
  end

  it 'Should contain interface_file /etc/network/interfaces.d/ifcfg-eth4' do
    rv = contain_file("#{interface_file}")
    should rv.with_content(/hwaddress\s+ether\s+#{params[:macaddr].downcase()}/)
    should rv.with_content(/address\s+1.2.3.4/)
    should rv.with_content(/auto\s+#{title}/)
    should rv.with_content(/iface\s+#{title}/)
  end

end

# Centos, static
describe 'l23network::l3::ifconfig', :type => :define do
  let(:module_path) { '../' }
  let(:title) { 'eth4' }
  let(:params) { {
    :ipaddr => '1.2.3.4/24',
    :macaddr => 'AA:BB:CC:33:22:11'
  } }
  let(:facts) { {
    :osfamily => 'RedHat',
    :operatingsystem => 'Centos',
    :kernel => 'Linux'
  } }
  let(:interface_file) { '/etc/sysconfig/network-scripts/ifcfg-eth4' }

  it 'Should contain interface_file /etc/sysconfig/network-scripts/ifcfg-eth4' do
    rv = contain_file("#{interface_file}")
    should rv.with_content(/MACADDR=#{params[:macaddr].upcase()}/)
    should rv.with_content(/IPADDR=1.2.3.4/)
    should rv.with_content(/DEVICE=#{title}/)
  end

end
