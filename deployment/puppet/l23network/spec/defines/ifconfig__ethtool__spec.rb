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
    :ipaddr  => '1.2.3.4/24',
    :ethtool => {
                  '-K' => 'gso off  gro off',
                  '--set-channels' => 'rx 1  tx 2  other 3'
                }
  } }
  let(:facts) { {
    :osfamily => 'Debian',
    :operatingsystem => 'Ubuntu',
    :kernel => 'Linux'
  } }
  let(:interface_file) { '/etc/network/interfaces.d/ifcfg-eth4' }

  it "Should contains interface_file" do
    should contain_file('/etc/network/interfaces').with_content(/\*/)
  end

  it 'Should contains post-up directives' do
    rv = contain_file("#{interface_file}")
    params[:ethtool].each do |k, v|
      # "--#{k}"" -- workaround for rspec-pupppet bug.
      should rv.with_content(/post-up\s+ethtool\s+--#{k}\s+#{title}\s+#{v}/)
    end
  end
end

# Centos, static
describe 'l23network::l3::ifconfig', :type => :define do
  let(:module_path) { '../' }
  let(:title) { 'eth4' }
  let(:params) { {
    :ipaddr => '1.2.3.4/24',
    :ethtool => {
                  '-K' => 'gso off  gro off',
                  '--set-channels' => 'rx 1  tx 2  other 3'
                }
  } }
  let(:facts) { {
    :osfamily => 'RedHat',
    :operatingsystem => 'Centos',
    :kernel => 'Linux'
  } }
  let(:interface_file) { '/etc/sysconfig/network-scripts/ifcfg-eth4' }
  let(:interface_up_file) { '/etc/sysconfig/network-scripts/interface-up-script-eth4' }

  it 'Should contains common ifup script file /sbin/ifup-local' do
    should contain_file("/sbin/ifup-local")
  end

  it 'Should contain interface post-up script' do
    rv = contain_file("#{interface_up_file}")
    params[:ethtool].each do |k, v|
      # "--#{k}"" -- workaround for rspec-pupppet bug.
      should rv.with_content(/ethtool\s+--#{k}\s+#{title}\s+#{v}/)
    end
  end

end
