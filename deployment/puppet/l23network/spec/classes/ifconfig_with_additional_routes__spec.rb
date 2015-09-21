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
  transformations: []
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

  context 'contains endpoint which additional routes' do
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

    context 'Ifconfig and L3::Route ordering' do
      it {should contain_L23network__L3__Ifconfig('eth2').that_comes_before('L23network::L3::Route[192.168.210.0/24,metric:10]') }
      it {should contain_L23network__L3__Route('192.168.210.0/24,metric:10').that_comes_before('L23network::L3::Route[192.168.211.0/24]') }
      it {should contain_L23network__L3__Route('192.168.211.0/24').that_comes_before('L23network::L3::Route[192.168.212.0/24]') }
    end

    it do
      should_not contain_l3_clear_route('default')
    end

  end
end

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
    - action: add-br
      name:   br-xx
    - action: add-port
      name:   eth2
      bridge: br-xx
  endpoints:
    br-xx:
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

  context 'contains full chain of ports, interfaces, bridges and endpoint with additionat routes' do
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
      should contain_l2_port('eth2')
    end

    it do
      should contain_l2_bridge('br-xx')
    end

    it do
      should contain_l3_ifconfig('br-xx').with({
        'ipaddr' => '192.168.101.3/24',
      })
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

    context 'Ifconfig and L3::Route ordering' do
      it {should contain_L23network__L3__Ifconfig('br-xx').that_comes_before('L23network::L3::Route[192.168.210.0/24,metric:10]') }
      it {should contain_L23network__L3__Route('192.168.210.0/24,metric:10').that_comes_before('L23network::L3::Route[192.168.211.0/24]') }
      it {should contain_L23network__L3__Route('192.168.211.0/24').that_comes_before('L23network::L3::Route[192.168.212.0/24]') }
    end

    it do
      should_not contain_l3_clear_route('default')
    end

  end

end

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
    - action: add-br
      name:   br-xx
    - action: add-br
      name:   br-yy
    - action: add-br
      name:   br-zz
    - action: add-port
      name:   eth2
      bridge: br-zz
  endpoints:
    br-xx:
      IP:
        - 192.168.101.3/24
      routes:
        - net: 192.168.210.0/24
          via: 192.168.101.1
          metric: 11
        - net: 192.168.211.0/24
          via: 192.168.101.1
        - net: 192.168.212.0/24
          via: 192.168.101.1
    br-yy:
      IP:
        - 192.168.102.3/24
      routes:
        - net: 192.168.220.0/24
          via: 192.168.102.1
          metric: 12
        - net: 192.168.221.0/24
          via: 192.168.102.1
        - net: 192.168.222.0/24
          via: 192.168.102.1
    br-zz:
      IP:
        - 192.168.103.3/24
      routes:
        - net: 192.168.230.0/24
          via: 192.168.103.1
          metric: 13
        - net: 192.168.231.0/24
          via: 192.168.103.1
        - net: 192.168.232.0/24
          via: 192.168.103.1
  roles: {}
eof
end

  context 'contains chain of two bridges, with endpoints, contains additionat routes' do
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
      should contain_l2_bridge('br-xx')
    end
    it do
      should contain_l2_bridge('br-yy')
    end
    it do
      should contain_l2_bridge('br-zz')
    end

    it do
      should contain_l3_route('192.168.210.0/24,metric:11').with({
        'ensure'      => 'present',
        'destination' => '192.168.210.0/24',
        'gateway'     => '192.168.101.1',
        'metric'      => 11
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

    context 'Ifconfig and L3::Route ordering for br-xx' do
      it {should contain_L23network__L3__Ifconfig('br-xx').that_comes_before('L23network::L3::Route[192.168.210.0/24,metric:11]') }
      it {should contain_L23network__L3__Route('192.168.210.0/24,metric:11').that_comes_before('L23network::L3::Route[192.168.211.0/24]') }
      it {should contain_L23network__L3__Route('192.168.211.0/24').that_comes_before('L23network::L3::Route[192.168.212.0/24]') }
    end

    it do
      should contain_l3_route('192.168.220.0/24,metric:12').with({
        'ensure'      => 'present',
        'destination' => '192.168.220.0/24',
        'gateway'     => '192.168.102.1',
        'metric'      => 12
      })
    end
    ['192.168.221.0/24', '192.168.222.0/24'].each do |dst|
      it do
        should contain_l3_route(dst).with({
          'ensure'      => 'present',
          'destination' => dst,
          'gateway'     => '192.168.102.1',
          'metric'      => nil
        })
      end
    end

    context 'Ifconfig and L3::Route ordering for br-yy' do
      it {should contain_L23network__L3__Ifconfig('br-yy').that_comes_before('L23network::L3::Route[192.168.220.0/24,metric:12]') }
      it {should contain_L23network__L3__Route('192.168.220.0/24,metric:12').that_comes_before('L23network::L3::Route[192.168.221.0/24]') }
      it {should contain_L23network__L3__Route('192.168.221.0/24').that_comes_before('L23network::L3::Route[192.168.222.0/24]') }
    end

    it do
      should contain_l3_route('192.168.230.0/24,metric:13').with({
        'ensure'      => 'present',
        'destination' => '192.168.230.0/24',
        'gateway'     => '192.168.103.1',
        'metric'      => 13
      })
    end
    ['192.168.231.0/24', '192.168.232.0/24'].each do |dst|
      it do
        should contain_l3_route(dst).with({
          'ensure'      => 'present',
          'destination' => dst,
          'gateway'     => '192.168.103.1',
          'metric'      => nil
        })
      end
    end

    context 'Ifconfig and L3::Route ordering for br-zz' do
      it {should contain_L23network__L3__Ifconfig('br-zz').that_comes_before('L23network::L3::Route[192.168.230.0/24,metric:13]') }
      it {should contain_L23network__L3__Route('192.168.230.0/24,metric:13').that_comes_before('L23network::L3::Route[192.168.231.0/24]') }
      it {should contain_L23network__L3__Route('192.168.231.0/24').that_comes_before('L23network::L3::Route[192.168.232.0/24]') }
    end

    it do
      should_not contain_l3_clear_route('default')
    end

  end

end

###
