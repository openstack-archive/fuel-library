require 'spec_helper'

describe 'l23network::l3::ifconfig', :type => :define do
  context 'ifconfig with dhcp' do
    let(:title) { 'ifconfig simple test' }
    let(:facts) { {
      :osfamily => 'Debian',
      :operatingsystem => 'Ubuntu',
      :l23_os => 'ubuntu',
      :kernel => 'Linux',
      :netrings => {
        'eth4' => {
          'maximums' => {'RX'=>'4096', 'TX'=>'4096'},
          'current' => {'RX'=>'256', 'TX'=>'256'}
        },
      }
    } }

    let(:params) { {
      :interface => 'eth4',
      :ipaddr => 'dhcp'
    } }

    let(:pre_condition) { [
      "class {'l23network': }"
    ] }

    let(:rings) do
      {
        'rings' => facts[:netrings][params[:interface]]['maximums']
      }
    end

    before(:each) do
      puppet_debug_override()
    end

    it do
      should compile.with_all_deps
    end

    it do
      should contain_l23_stored_config('eth4').only_with({
        'ensure'          => 'present',
        'name'            => 'eth4',
        'method'          => 'dhcp',
        'ipaddr'          => 'dhcp',
        'gateway'         => nil,
        'vendor_specific' => {},
        'ethtool'         => rings,
      })
    end

    it do
      should contain_l3_ifconfig('eth4').with({
        'ensure'  => 'present',
        'ipaddr'  => ['dhcp'],
        'gateway' => nil,
      }).that_requires('L23_stored_config[eth4]')
    end


  end

end

# # Ubintu, dhcp, ordered iface
# describe 'l23network::l3::ifconfig', :type => :define do
#   let(:module_path) { '../' }
#   let(:title) { 'ifconfig simple test' }
#   let(:params) { {
#     :interface => 'eth4',
#     :ipaddr => 'dhcp',
#     :ifname_order_prefix => 'zzz'
#   } }
#   let(:facts) { {
#     :osfamily => 'Debian',
#     :operatingsystem => 'Ubuntu',
#     :kernel => 'Linux'
#   } }
#   let(:interface_file_start) { '/etc/network/interfaces.d/ifcfg-' }

#   it "Ubintu/dhcp: ordered.ifaces: Should contain interface_file" do
#     should contain_file('/etc/network/interfaces').with_content(/\*/)
#   end

#   it "Ubintu/dhcp: ordered.ifaces: interface file shouldn't contain ipaddr and netmask" do
#     rv = contain_file("#{interface_file_start}#{params[:ifname_order_prefix]}-#{params[:interface]}")
#     should rv.without_content(/address/)
#     should rv.without_content(/netmask/)
#   end

#   it "Ubintu/dhcp: ordered.ifaces: interface file should contain ifup/ifdn commands" do
#     rv = contain_file("#{interface_file_start}#{params[:ifname_order_prefix]}-#{params[:interface]}")
#     should rv.without_content(/address/)
#     should rv.without_content(/netmask/)
#   end

#   it "Ubintu/dhcp: ordered.ifaces: interface file shouldn't contains bond-master options" do
#     rv = contain_file("#{interface_file_start}#{params[:ifname_order_prefix]}-#{params[:interface]}")
#     should rv.without_content(/bond-mode/)
#     should rv.without_content(/slaves/)
#   end
# end

# # Centos, dhcp
# describe 'l23network::l3::ifconfig', :type => :define do
#   let(:module_path) { '../' }
#   let(:title) { 'ifconfig simple test' }
#   let(:params) { {
#     :interface => 'eth4',
#     :ipaddr => 'dhcp'
#   } }
#   let(:facts) { {
#     :osfamily => 'RedHat',
#     :operatingsystem => 'Centos',
#     :kernel => 'Linux'
#   } }
#   let(:interface_file_start) { '/etc/sysconfig/network-scripts/ifcfg-' }
#   let(:interface_up_file_start) { '/etc/sysconfig/network-scripts/interface-up-script-' }

#   it 'Centos/dhcp: interface file should contains true header' do
#     rv = contain_file("#{interface_file_start}#{params[:interface]}")
#     should rv.with_content(/DEVICE=#{params[:interface]}/)
#     should rv.with_content(/BOOTPROTO=dhcp/)
#     should rv.with_content(/ONBOOT=yes/)
#   end

#   it "Centos/dhcp: Shouldn't contains interface_file with IP-addr" do
#     rv = contain_file("#{interface_file_start}#{params[:interface]}")
#     should rv.without_content(/IPADDR=/)
#     should rv.without_content(/NETMASK=/)
#   end
# end

# # Centos, dhcp, ordered iface
# describe 'l23network::l3::ifconfig', :type => :define do
#   let(:module_path) { '../' }
#   let(:title) { 'ifconfig simple test' }
#   let(:params) { {
#     :interface => 'eth4',
#     :ipaddr => 'dhcp',
#     :ifname_order_prefix => 'zzz'
#   } }
#   let(:facts) { {
#     :osfamily => 'RedHat',
#     :operatingsystem => 'Centos',
#     :kernel => 'Linux'
#   } }
#   let(:interface_file_start) { '/etc/sysconfig/network-scripts/ifcfg-' }
#   let(:interface_up_file_start) { '/etc/sysconfig/network-scripts/interface-up-script-' }

#   it 'Centos/dhcp: ordered.ifaces: interface file should contains true header' do
#     rv = contain_file("#{interface_file_start}#{params[:ifname_order_prefix]}-#{params[:interface]}")
#     should rv.with_content(/DEVICE=#{params[:interface]}/)
#     should rv.with_content(/BOOTPROTO=dhcp/)
#     should rv.with_content(/ONBOOT=yes/)
#   end

#   it 'Centos/dhcp: ordered.ifaces: Should contains interface_file with IP-addr' do
#     rv = contain_file("#{interface_file_start}#{params[:ifname_order_prefix]}-#{params[:interface]}")
#     should rv.without_content(/IPADDR=/)
#     should rv.without_content(/NETMASK=/)
#   end
# end
