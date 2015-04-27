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
  endpoints:
    eth2:
      IP:
        - 192.168.101.3/24
      routes:
        - net: 192.168.210.0/24
          via: 192.168.101.1
          metric: 10
        - net: 192.168.211.0/24
          via: 192.168.101.1
        - net: 192.168.212.0/24
          via: 192.168.101.1
  roles: {}
eof
end

let(:expected_routes) do
  {
      '192.168.210.0/24,metric:10' => {
          'gateway' => '192.168.101.1',
          'destination' => '192.168.210.0/24',
          'metric' => '10'
      },
      '192.168.211.0/24' => {
          'gateway' => '192.168.101.1',
          'destination' => '192.168.211.0/24'
      },
      '192.168.212.0/24' => {
          'gateway' => '192.168.101.1',
          'destination' => '192.168.212.0/24'
      }
  }
end

  context 'network scheme with endpoint, which contained additionat routes' do
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
        'ipaddr' => '192.168.101.3/24',
      })
    end

    it 'should collect routes set' do
      ral = catalogue.to_ral()
      l23_stored_config_eth2 = ral.resource('l23_stored_config', 'eth2')
      l23_stored_config_eth2.generate()
      expect(l23_stored_config_eth2[:routes]).to eq(expected_routes)
    end

    it do
      should contain_l3_route('192.168.210.0/24,metric:10').with({
        'ensure'      => 'present',
        'destination' => '192.168.210.0/24',
        'gateway'     => '192.168.101.1',
        'metric'      => 10
      })
    end

    ['192.168.211.0/24', '192.168.212.0/24'].each do |dst|
      it do
        should contain_l3_route(dst).with({
          'ensure'      => 'present',
          'destination' => dst,
          'gateway'     => '192.168.101.1',
          'metric'      => nil
        })
      end
    end
  end

end

###
