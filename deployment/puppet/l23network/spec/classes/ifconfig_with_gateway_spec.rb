require 'spec_helper'

describe 'l23network::examples::run_network_scheme', :type => :class do
let(:network_scheme) do
<<eof
---
network_scheme:
  version: 1.1
  provider: lnx
  interfaces:
    eth2: {}
  transformations:
    - action: add-port
      name:   eth2
    - action: add-port
      name:   eth3
  endpoints:
    eth2:
      IP:
        - 192.168.101.3/24
      gateway: 192.168.101.1
    eth3:
      IP:
        - 172.16.55.34/24
      gateway: 172.16.55.1
      gateway_metric: 88
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

    it do
      should compile
    end

    it do
      should contain_l2_port('eth2')
    end

    it do
      should contain_l3_ifconfig('eth2').with({
        'ipaddr'  => '192.168.101.3/24',
        'gateway' => '192.168.101.1',
      })
    end

    it do
      should contain_l3_ifconfig('eth3').with({
        'ipaddr'         => '172.16.55.34/24',
        'gateway'        => '172.16.55.1',
        'gateway_metric' => '88',
      })
    end


    it do
      should contain_l3_clear_route('default').with ({ 'ensure'  => 'absent', 'destination' => 'default' })
    end

    it do
      should contain_l3_clear_route('default,metric:88').with ({ 'ensure'  => 'absent', 'destination' => 'default' })
    end

  end

end

###
