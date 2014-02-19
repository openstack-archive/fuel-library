# require 'puppet'
# require 'rspec'
# require 'rspec-puppet'
require 'spec_helper'
require 'puppetlabs_spec_helper/puppetlabs_spec/puppet_internals'
require 'json'
require 'yaml'

class NeutronNRConfig
  def initialize(init_v)
    @def_v = {}
    @def_v.replace(init_v)
    @def_config = {
        'predefined_networks' => {
          'net04_ext' => {
            'shared' => false,
            'L2' => {
              'router_ext'   => true,
              'network_type' => 'flat',
              'physnet'      => 'physnet1',
              'segment_id'   => nil,
            },
            'L3' => {
              'subnet' => "10.100.100.0/24",
              'gateway' => "10.100.100.1",
              'nameservers' => [],
              'floating' => "10.100.100.130:10.100.100.254",
            },
          },
          'net04' => {
            'shared' => false,
            'L2' => {
              'router_ext'   => false,
              'network_type' => 'gre', # or vlan
              'physnet'      => 'physnet2',
              'segment_id'   => nil,
            },
            'L3' => {
              'subnet' => "192.168.111.0/24",
              'gateway' => "192.168.111.1",
              'nameservers' => ["8.8.4.4", "8.8.8.8"],
              'floating' => nil,
            },
          },
        },
    }
    init_v.each() do |k,v|
      @def_config[k.to_s()] = v
    end
  end

  def get_def_config()
    return Marshal.load(Marshal.dump(@def_config))
  end

  def get_def(k)
    return @def_v[k]
  end

end

describe 'get_floatingip_pool_size_for_admin' , :type => :puppet_function do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  before :each do
    @qnr_config = NeutronNRConfig.new({
      :management_vip => '192.168.0.254',
      :management_ip => '192.168.0.11'
    })
    # Puppet::Parser::Scope.any_instance.stubs(:function_get_network_role_property).with('management', 'ipaddr').returns(@q_config.get_def(:management_ip))
    @cfg = @qnr_config.get_def_config()
  end

  it 'should exist' do
    Puppet::Parser::Functions.function('get_floatingip_pool_size_for_admin').should == 'function_get_floatingip_pool_size_for_admin'
  end

  it 'Should return 10' do
    expect(scope.function_get_floatingip_pool_size_for_admin([@cfg, 'neutron_settings'])).to eq(10)
    # [
    #   '10.100.100.244',
    #   '10.100.100.245',
    #   '10.100.100.246',
    #   '10.100.100.247',
    #   '10.100.100.248',
    #   '10.100.100.249',
    #   '10.100.100.250',
    #   '10.100.100.251',
    #   '10.100.100.252',
    #   '10.100.100.253',
    #   '10.100.100.254'
    # ]
  end

  it 'Should return zero' do
    @cfg['predefined_networks']['net04_ext']['L3']['floating'] = "10.100.100.250:10.100.100.254"
    expect(scope.function_get_floatingip_pool_size_for_admin([@cfg, 'neutron_settings'])).to eq(0)
  end

  it 'Should return 2' do
    @cfg['predefined_networks']['net04_ext']['L3']['floating'] = "10.100.100.247:10.100.100.254"
    expect(scope.function_get_floatingip_pool_size_for_admin([@cfg, 'neutron_settings'])).to eq(2)
  end

  it 'Should return 10' do
    @cfg['predefined_networks']['net04_ext']['L3']['floating'] = "10.100.100.237:10.100.100.254"
    expect(scope.function_get_floatingip_pool_size_for_admin([@cfg, 'neutron_settings'])).to eq(10)
  end

end

# vim: set ts=2 sw=2 et :