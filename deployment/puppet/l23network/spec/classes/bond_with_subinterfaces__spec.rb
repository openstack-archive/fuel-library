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
      name: eth2.101
    - action: add-port
      name: eth3.101
    - action: add-bond
      name: bond23
      interfaces:
        - eth2.101
        - eth3.101
      bond_properties:
        mode: balance-rr
  emdpoints: {}
  roles: {}
eof
end


  context 'with bond (lnx) two subinterfaces' do
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
      if ENV['SPEC_PUPPET_DEBUG']
        Puppet::Util::Log.level = :debug
        Puppet::Util::Log.newdestination(:console)
      end
    end

    it do
      should compile.with_all_deps
    end

    it do
      should contain_l2_bond('bond23').with({
        'ensure' => 'present',
        'slaves' => ['eth2.101', 'eth3.101'],
      })
    end

    ['eth2.101', 'eth3.101'].each do |iface|
      it do
        should contain_l2_port(iface).with({
          'ensure'       => 'present',
          'bond_master'  => 'bond23',
        })
      end
      it do
        should contain_l23_stored_config(iface).with({
          'ensure'       => 'present',
          'bond_master'  => 'bond23',
        })
      end
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
    eth3: {}
  transformations:
    - action: add-port
      name: eth2.101
    - action: add-port
      name: eth3.101
    - action: add-bond
      name: bond23
      interfaces:
        - eth2.101
        - eth3.101
      bridge: br-bond23
      bond_properties:
        mode: balance-rr
      provider: ovs
  emdpoints: {}
  roles: {}
eof
end

  context 'with bond (ovs) two subinterfaces' do
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
      if ENV['SPEC_PUPPET_DEBUG']
        Puppet::Util::Log.level = :debug
        Puppet::Util::Log.newdestination(:console)
      end
    end

    it do
      should compile.with_all_deps
    end

    it do
      should contain_l2_bond('bond23').with({
        'provider' => 'ovs',
        'ensure' => 'present',
        'slaves' => ['eth2.101', 'eth3.101'],
        'bridge' => 'br-bond23',
      })
    end

    ['eth2.101', 'eth3.101'].each do |iface|
      it do
        should contain_l2_port(iface).with({
          'ensure'       => 'present',
          'bond_master'  => nil,
        })
      end
      it do
        should contain_l23_stored_config(iface).with({
          'ensure'       => 'present',
          'bond_master'  => nil,
        })
      end
    end

  end

end

###
