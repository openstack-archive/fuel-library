require 'spec_helper'

describe Puppet::Parser::Functions.function(:get_network_role_property) do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  subject do
    function_name = Puppet::Parser::Functions.function(:get_network_role_property)
    scope.method(function_name)
  end

  context "mtk" do
    before(:each) do
      #Puppet::Parser::Scope.any_instance.stubs(:lookupvar).with('l3_fqdn_hostname').returns('node1.tld')
      scope.stubs(:lookupvar).with('l3_fqdn_hostname').returns('node1.tld')
      L23network::Scheme.set_config(scope.lookupvar('l3_fqdn_hostname'), {
        :transformations => [ {
          :bridge => 'br-ex',
          :name => 'bond0',
          :mtu => 1450,
          :interfaces => ["eth1", "eth2"],
        }, ],
        :interfaces => {
          :eth0 => {},
        },
        :endpoints => {
          :eth0 => {:IP => 'dhcp'},
          :"br-ex" => {
            :gateway => '10.1.3.1',
            :IP => ['10.1.3.11/24'],
          },
          :"br-mgmt" => { :IP => ['10.20.1.11/25'] },
          :"br-storage" => { :IP => ['192.168.1.2/24'] },
          :"br-prv" => { :IP => 'none' },
        },
        :roles => {
          :management => 'br-mgmt',
          :private => 'br-prv',
          :ex => 'br-ex',
          :storage => 'br-storage',
          :admin => 'eth0',
        },
      })
    end

    it 'should exist' do
      subject == Puppet::Parser::Functions.function(:get_network_role_property)
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

    it 'should return cidr-notated network address for "management" network role' do
      should run.with_params('management', 'network').and_return('10.20.1.0/25')
    end

    it 'should return netmask for "management" network role' do
      should run.with_params('management', 'netmask').and_return('255.255.255.128')
    end

    it 'should return ip address and netmask for "management" network role' do
      should run.with_params('management', 'ipaddr_netmask_pair').and_return(['10.20.1.11','255.255.255.128'])
    end

    it 'should return physical device name for "ex" network role' do
      should run.with_params('ex', 'phys_dev').and_return(["bond0", "eth1", "eth2"])
    end

    it 'should return NIL for "admin" network role' do
      should run.with_params('admin', 'netmask').and_return(nil)
    end
    it 'should return NIL for "admin" network role' do
      should run.with_params('admin', 'ipaddr').and_return(nil)
    end
    it 'should return NIL for "admin" network role' do
      should run.with_params('admin', 'cidr').and_return(nil)
    end
    it 'should return NIL for "admin" network role' do
      should run.with_params('admin', 'ipaddr_netmask_pair').and_return(nil)
    end
    it 'should return NIL for "admin" network role' do
      should run.with_params('admin', 'phys_dev').and_return(nil)
    end
  end

end
