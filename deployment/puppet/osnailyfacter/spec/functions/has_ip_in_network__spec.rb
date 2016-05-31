require 'spec_helper'

describe 'has_ip_in_network' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it 'should exist' do
    Puppet::Parser::Functions.function('has_ip_in_network').should == 'function_has_ip_in_network'
  end

  it 'should throw an error on invalid arguments number' do
    lambda {
      scope.function_has_ip_in_network(['foo'])
    }.should(raise_error(ArgumentError))
  end

  it 'should raise an error if invalid address or network is specified' do
    lambda {
      scope.function_has_ip_in_network(['foo', 'bar'])
    }.should(raise_error(Puppet::ParseError))
  end

  it 'should return true if IP address is from CIDR' do
    cidr = '192.168.0.0/16'
    ipaddr = '192.168.33.66'
    scope.function_has_ip_in_network([ipaddr, cidr]).should == true
  end

  it 'should return false if IP address is not from CIDR' do
    cidr = '192.168.0.0/255.255.0.0'
    ipaddr = '172.16.0.1'
    scope.function_has_ip_in_network([ipaddr, cidr]).should == false
  end

end
