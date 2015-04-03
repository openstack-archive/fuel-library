require 'spec_helper'

describe Puppet::Parser::Functions.function(:get_transformation_property) do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  subject do
    function_name = Puppet::Parser::Functions.function(:get_transformation_property)
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
      subject == Puppet::Parser::Functions.function(:get_transformation_property)
    end

    it 'should return mtu value for "bond0" transformation' do
      should run.with_params('mtu', ["bond0", ["eth1", "eth2"]]).and_return(1450)
    end

    it 'should return NIL for "eth0" transformation' do
      should run.with_params('eth0', 'mtu').and_return(nil)
    end
  end

end
