require 'spec_helper'

describe 'l23network::examples::run_network_scheme', :type => :class do
let(:network_scheme) do
<<eof
---
network_scheme:
  version: 1.1
  provider: lnx
  interfaces:
    ib2: {}
  transformations:
    - action:   add-port
      name:     ib2.8001
      vlan_dev: false
  endpoints:
    ib2.8001:
      IP:
        - 192.168.101.3/24
  roles: {}
eof
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
      should contain_l2_port('ib2')
    end

    it do
      should contain_l2_port('ib2.8001').with({
        'vlan_dev'  => nil,
        'vlan_id'   => nil,
        'vlan_mode' => nil,
      })
    end

    it do
      should contain_l3_ifconfig('ib2.8001').with({
        'ipaddr' => '192.168.101.3/24',
      })
    end

  end

end

###
