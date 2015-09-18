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
        - 192.168.101.1/24
        - 192.168.102.2/24
        - 192.168.103.3/24
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
      should contain_L2_port('eth2')
    end

    it do
      should contain_L23network__L3__Ifconfig('eth2').with({
        'ipaddr'  => ['192.168.101.1/24','192.168.102.2/24','192.168.103.3/24',],
        'gateway' => nil,
      })
    end

    it do
      should contain_L23network__L3__Ifconfig('eth2').that_requires("L23network::L2::Port[eth2]")
    end

  end

end

###
