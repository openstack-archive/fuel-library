require 'spec_helper'

describe Puppet::Parser::Functions.function(:configure_default_route) do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }
  let(:hiera_data) { { :master_ip => "2.2.2.2" } }

  subject do
    function_name = Puppet::Parser::Functions.function(:configure_default_route)
    scope.method(function_name)
  end

  context "MY test" do
    before(:each) do
      #Puppet::Parser::Scope.any_instance.stubs(:lookupvar).with('l3_fqdn_hostname').returns('node1.tld')
      scope.stubs(:lookupvar).with('l3_fqdn_hostname').returns('node1.tld')
      L23network::Scheme.set_config(scope.lookupvar('l3_fqdn_hostname'),{
        :transformations=>[
          {:action=>\"add-br\", :name=>\"br-fw-admin\"},
          {:action=>\"add-br\", :name=>\"br-mgmt\"},
          {:action=>\"add-br\", :name=>\"br-storage\"},
          {:action=>\"add-br\", :name=>\"br-prv\", :provider=>\"ovs\"}, 
          {:action=>\"add-patch\", :bridges=>[\"br-prv\", \"br-fw-admin\"], :provider=>\"ovs\"},
          {:action=>\"add-port\", :bridge=>\"br-fw-admin\", :name=>\"eth0\"}, 
          {:action=>\"add-port\", :bridge=>\"br-storage\", :name=>\"eth0.102\"},
          {:action=>\"add-port\", :bridge=>\"br-mgmt\", :name=>\"eth0.101\"}],
        :roles=>{
          :\"neutron/private\"=>\"br-prv\",
          :management=>\"br-mgmt\", 
          :storage=>\"br-storage\",
          :\"fw-admin\"=>\"br-fw-admin\"},
        :interfaces=>{
          :eth4=>{:vendor_specific=>{:driver=>\"e1000\", :bus_info=>\"0000:00:07.0\"}}, :eth3=>{:vendor_specific=>{:driver=>\"e1000\", :bus_info=>\"0000:00:06.0\"}}, 
          :eth2=>{:vendor_specific=>{:driver=>\"e1000\", :bus_info=>\"0000:00:05.0\"}}, :eth1=>{:vendor_specific=>{:driver=>\"e1000\", :bus_info=>\"0000:00:04.0\"}}, 
          :eth0=>{:vendor_specific=>{:driver=>\"e1000\", :bus_info=>\"0000:00:03.0\"}}}, :version=>\"1.1\", :provider=>\"lnx\", 
        :endpoints=>{
          :\"br-fw-admin\"=>{:IP=>[\"10.109.5.11/24\"], :gateway=>\"10.109.5.2\"}, :\"br-storage\"=>{:IP=>[\"192.168.1.3/24\"], :vendor_specific=>{:phy_interfaces=>[\"eth0\"], :vlans=>102}},
          :\"br-mgmt\"=>{:IP=>[\"192.168.0.5/24\"], :vendor_specific=>{:phy_interfaces=>[\"eth0\"], :vlans=>101}}, 
          :\"br-prv\"=>{:IP=>nil, :vendor_specific=>{:phy_interfaces=>[\"eth0\"], :vlans=>\"1000:1030\"}}}
      })
    end

    it 'should exist' do
      subject == Puppet::Parser::Functions.function(:configure_default_route)
    end

    it 'should return interface name for "private" network role' do
      should run.with_params('private', 'interface').and_return('br-prv')
    end

    it 'should raise for non-existing role name' do
      subject.call(['not_exist', 'interface']).should == nil
    end

    it 'should return ip address for "management" network role' do
      should run.with_params('management', 'ipaddr').and_return('10.20.1.11')
    end

    it 'should return cidr-notated ip address for "management" network role' do
      should run.with_params('management', 'cidr').and_return('10.20.1.11/25')
    end

    it 'should return netmask for "management" network role' do
      should run.with_params('management', 'netmask').and_return('255.255.255.128')
    end

    it 'should return ip address and netmask for "management" network role' do
      should run.with_params('management', 'ipaddr_netmask_pair').and_return(['10.20.1.11','255.255.255.128'])
    end

  end

end
