require 'spec_helper'

describe 'l23network::l3::ifconfig', :type => :define do
  context 'without IP address definition' do
    let(:title) { 'without IP address definition' }
    let(:facts) { {
      :osfamily => 'Debian',
      :operatingsystem => 'Ubuntu',
      :l23_os => 'ubuntu',
      :kernel => 'Linux',
      :netrings => {
        'eth4' => {
          'maximums' => {'rx'=>'4096', 'tx'=>'4096'},
          'current' => {'rx'=>'256', 'tx'=>'256'}
        },
      }
    } }

    let(:params) { {
      :interface => 'eth4',
      :ipaddr => 'none'
    } }

    let(:pre_condition) do
      definition_pre_condition
    end

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
        'method'          => 'manual',
        'ipaddr'          => 'none',
        'ipaddr_aliases'  => nil,
        'vendor_specific' => {},
        'ethtool'         => rings,
      })
    end

    it do
      should contain_l3_ifconfig('eth4').with({
        'ensure'  => 'present',
        'ipaddr'  => ['none'],
        'gateway' => nil,
      })
    end

    it do
      should contain_l3_ifconfig('eth4').that_requires('L23_stored_config[eth4]')
      should contain_l3_ifconfig('eth4').that_requires('L23network::L2::Port[eth4]')
    end
  end

  context 'with IP address and default gateway' do
    let(:title) { 'ifconfig simple test' }
    let(:facts) { {
      :osfamily => 'Debian',
      :operatingsystem => 'Ubuntu',
      :l23_os => 'ubuntu',
      :kernel => 'Linux'
    } }

    let(:params) { {
      :interface => 'eth4',
      :ipaddr  => ['10.20.20.2/24'],
      :gateway => '10.20.20.1',
    } }

    before(:each) do
      puppet_debug_override()
    end

    it do
      should compile.with_all_deps
    end

    it do
      should contain_l23_stored_config('eth4').with({
        'ensure'         => 'present',
        'name'           => 'eth4',
        'method'         => 'static',
        'ipaddr'         => '10.20.20.2/24',
        'gateway'        => '10.20.20.1',
        'gateway_metric' => nil,
      })
    end

    it do
      should contain_l3_ifconfig('eth4').with({
        'ensure'         => 'present',
        'ipaddr'         => ['10.20.20.2/24'],
        'gateway'        => '10.20.20.1',
        'gateway_metric' => nil,
      })
    end

    it do
      should contain_l3_ifconfig('eth4').that_requires('L23_stored_config[eth4]')
      should contain_l3_ifconfig('eth4').that_requires('L23network::L2::Port[eth4]')
    end
  end

  context 'with default gateway and metric' do
    let(:title) { 'ifconfig simple test' }
    let(:facts) { {
      :osfamily => 'Debian',
      :operatingsystem => 'Ubuntu',
      :l23_os => 'ubuntu',
      :kernel => 'Linux'
    } }

    let(:params) { {
      :interface => 'eth4',
      :ipaddr  => ['10.20.30.2/24'],
      :gateway => '10.20.30.1',
      :gateway_metric => 321,
    } }

    before(:each) do
      puppet_debug_override()
    end

    it do
      should compile.with_all_deps
    end

    it do
      should contain_l23_stored_config('eth4').with({
        'ensure'         => 'present',
        'name'           => 'eth4',
        'method'         => 'static',
        'ipaddr'         => '10.20.30.2/24',
        'gateway'        => '10.20.30.1',
        'gateway_metric' => 321,
      })
    end

    it do
      should contain_l3_ifconfig('eth4').with({
        'ensure'         => 'present',
        'ipaddr'         => ['10.20.30.2/24'],
        'gateway'        => '10.20.30.1',
        'gateway_metric' => 321,
      })
    end

    it do
      should contain_l3_ifconfig('eth4').that_requires('L23_stored_config[eth4]')
      should contain_l3_ifconfig('eth4').that_requires('L23network::L2::Port[eth4]')
    end
  end

  context 'with multiple IP addresses' do
    let(:title) { 'with multiple IP addresses' }
    let(:facts) { {
      :osfamily => 'Debian',
      :operatingsystem => 'Ubuntu',
      :l23_os => 'ubuntu',
      :kernel => 'Linux'
    } }

    let(:params) { {
      :interface => 'eth4',
      :ipaddr  => ['10.20.20.2/24', '10.30.30.3/24', '10.40.40.4/24'],
    } }

    before(:each) do
      puppet_debug_override()
    end

    it do
      should compile.with_all_deps
    end

    it do
      should contain_l23_stored_config('eth4').with({
        'ensure'         => 'present',
        'name'           => 'eth4',
        'method'         => 'static',
        'ipaddr'         => '10.20.20.2/24',
        'ipaddr_aliases' => ['10.30.30.3/24', '10.40.40.4/24'],
        'gateway'        => nil,
        'gateway_metric' => nil,
      })
    end

    it do
      should contain_l3_ifconfig('eth4').with({
        'ensure'         => 'present',
        'ipaddr'         => ['10.20.20.2/24', '10.30.30.3/24', '10.40.40.4/24'],
        'gateway'        => nil,
        'gateway_metric' => nil,
      })
    end

    it do
      should contain_l3_ifconfig('eth4').that_requires('L23_stored_config[eth4]')
      should contain_l3_ifconfig('eth4').that_requires('L23network::L2::Port[eth4]')
    end
  end

  context 'l3_ifconfig before port' do
    let(:title) { 'ifconfig simple test' }
    let(:facts) { {
      :osfamily => 'Debian',
      :operatingsystem => 'Ubuntu',
      :l23_os => 'ubuntu',
      :kernel => 'Linux'
    } }

    let :pre_condition do
      'l23network::l2::port{"port-test":}'
    end

    let(:params) { {
      :interface => 'port-test',
      :ipaddr  => ['10.10.10.1/24'],
    } }

    before(:each) do
      puppet_debug_override()
    end

    it do
      should compile.with_all_deps
    end

    it do
      should contain_l3_ifconfig('port-test').that_requires('L23network::L2::Port[port-test]')
    end
  end

  context 'l3_ifconfig before bridge' do
    let(:title) { 'ifconfig simple test' }
    let(:facts) { {
      :osfamily => 'Debian',
      :operatingsystem => 'Ubuntu',
      :l23_os => 'ubuntu',
      :kernel => 'Linux'
    } }

    let :pre_condition do
      'l23network::l2::bridge{"br-test":}'
    end

    let(:params) { {
      :interface => 'br-test',
      :ipaddr  => ['10.10.10.10/24'],
    } }

    before(:each) do
      puppet_debug_override()
    end

    it do
      should compile.with_all_deps
    end

    it do
      should contain_l3_ifconfig('br-test').that_requires('L23network::L2::Bridge[br-test]')
    end
  end

  context 'l3_ifconfig before bond' do
    let(:title) { 'ifconfig simple test' }
    let(:facts) { {
      :osfamily => 'Debian',
      :operatingsystem => 'Ubuntu',
      :kernel => 'Linux',
      :l23_os => 'ubuntu',
      :l3_fqdn_hostname => 'stupid_hostname',
    } }

    let(:pre_condition) { [
      "class {'l23network': }"
    ] }

    let :pre_condition do
      'l23network::l2::bond{"bond-test":
         interfaces      => ["eth2", "eth3"],
         bond_properties => {
           mode          => "802.3ad",
         },
         provider        => "lnx",
       }'
    end

    let(:params) { {
      :interface => 'bond-test',
      :ipaddr  => ['10.10.10.11/24'],
    } }

    before(:each) do
      puppet_debug_override()
    end

    it do
      should compile.with_all_deps
    end

    it do
      should contain_l3_ifconfig('bond-test').that_requires('L23network::L2::Bond[bond-test]')
    end
  end

end
