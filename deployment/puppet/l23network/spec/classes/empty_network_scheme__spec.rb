require 'rspec-puppet'
require 'spec_helper'
require 'puppetlabs_spec_helper/puppetlabs_spec/puppet_internals'

$network_scheme = "
---
network_scheme:
  version: 1.1
  provider: lnx
  interfaces: {}
  transformations: {}
  emdpoints: {}
  roles: {}
"


describe 'l23network::examples::run_network_scheme', :type => :class do
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
      :settings_yaml => $network_scheme
    } }

    it do
      should compile
    end

  end

end

###