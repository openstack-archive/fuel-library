require 'spec_helper'

describe 'l23network::examples::run_network_scheme', :type => :class do
let(:network_scheme) do
<<eof
---
network_scheme:
  version: 1.1
  provider: lnx
  interfaces:
    eth1: {}
    eth2: {}
  transformations:
    - action: add-port
      name:   eth1
    - action: add-port
      name:   eth2
    - action: add-port
      name:   eth3
  endpoints:
    eth1:
      IP:
        - 192.168.100.13/24
      gateway: ""
    eth2:
      IP:
        - 192.168.101.3/24
      gateway: 192.168.101.1
  roles: {}
eof
end

  context 'network scheme with endpoint, which contained gateway' do
    let(:title) { 'empty network scheme' }
    let(:facts) {
      {
        :osfamily => 'Debian',
        :operatingsystem => 'Ubuntu',
        :kernel => 'Linux',
        :l23_os => 'ubuntu',
        :l3_fqdn_hostname => 'stupid_hostname',
      }
    }

    let(:params) do {
      :settings_yaml => network_scheme,
    } end

    before(:each) do
      puppet_debug_override()
    end

    it do
      should compile.with_all_deps
    end

    it do
      should contain_l3_ifconfig('eth1').with({
        'ipaddr'  => '192.168.100.13/24'
      })
    end

    it 'eth1 without gateway' do
      should contain_l3_ifconfig('eth1').without_gateway
    end

    it do
      should contain_l3_ifconfig('eth2').with({
        'ipaddr'  => '192.168.101.3/24',
        'gateway' => '192.168.101.1',
      })
    end

    it do
      should contain_l3_clear_route('default').with ({ 'ensure'  => 'absent', 'destination' => 'default' })
    end

  end

end

