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
    eth3: {}
  transformations:
    - action: add-port
      name:   eth2.102
    - action: add-port
      name:   eth3.103
  endpoints:
    eth2.102:
      IP:
        - 192.168.101.3/24
    eth3.103:
      IP:
        - 192.168.101.3/24
  roles: {}
eof
end

  context 'network scheme with transformations and endpoint' do
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
      should compile.with_all_deps
    end

    it do
      should contain_L23network__L2__Port('eth2')
    end

    it do
      should contain_L23network__L2__Port('eth2.102')
    end
    it do
      should contain_L23network__L2__Port('eth2.102').that_requires('L23network::L2::Port[eth2]')
    end

    it do
      should contain_L23network__L3__Ifconfig('eth2.102')
    end
    it do
      should contain_L23network__L3__Ifconfig('eth2.102').that_requires('L23network::L2::Port[eth2.102]')
    end

    it do
      should contain_L23network__L2__Port('eth3')
    end

    it do
      should contain_L23network__L2__Port('eth3.103')
    end
    it do
      should contain_L23network__L2__Port('eth3.103').that_requires("L23network::L2::Port[eth3]")
    end

    it do
      should contain_L23network__L3__Ifconfig('eth3.103')
    end
    it do
      should contain_L23network__L3__Ifconfig('eth3.103').that_requires("L23network::L2::Port[eth3.103]")
    end

  end

end

###
