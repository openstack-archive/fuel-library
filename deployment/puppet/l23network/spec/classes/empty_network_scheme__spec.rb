require 'spec_helper'

describe 'l23network::examples::run_network_scheme', :type => :class do
let(:network_scheme) {
<<eof
---
network_scheme:
  version: 1.1
  provider: lnx
  interfaces: {}
  transformations: {}
  emdpoints: {}
  roles: {}
eof
}

  context 'parse minimal (empty) network scheme' do
    let(:title) { 'empty network scheme' }
    let(:facts) { {
      :osfamily => 'Debian',
      :operatingsystem => 'Ubuntu',
      :kernel => 'Linux',
      :l23_os => 'ubuntu',
      :l3_fqdn_hostname => 'stupid_hostname',
    } }

    let(:params) { {
      :settings_yaml => network_scheme
    } }

    before(:each) do
      puppet_debug_override()
    end

    it do
      should compile.with_all_deps
    end

    it 'should not contain l3_clear_route' do
      should_not contain_l3_clear_route('default').with ({ 'ensure'  => 'absent' })
    end
  end
end

# vim: set ts=2 sw=2 et :