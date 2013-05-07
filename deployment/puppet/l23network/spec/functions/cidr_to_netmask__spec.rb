require 'spec_helper'

describe 'cidr_to_netmask' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it 'should exist' do
    Puppet::Parser::Functions.function('cidr_to_netmask').should == 'function_cidr_to_netmask'
  end

  it 'should throw an error on invalid types' do
    lambda {
      scope.function_cidr_to_netmask([{:foo => :bar}])
    }.should(raise_error(Puppet::ParseError))
  end

  it 'should throw an error on invalid CIDR' do
    invalid_cidrs = ['192.168.33.66', '192.256.33.66/23', 'jhgjhgghggh']
    for cidr in invalid_cidrs
	    lambda {
	      scope.function_cidr_to_netmask([cidr])
	    }.should(raise_error(Puppet::ParseError))
    end
  end

  it 'should throw an error on invalid CIDR masklen' do
    cidr = '192.168.33.66/33'
    lambda {
      scope.function_cidr_to_netmask([cidr])
    }.should(raise_error(Puppet::ParseError))
  end

  it 'should return netmask from CIDR' do
    cidr = '192.168.33.66/25'
    netmask = '255.255.255.128'
    scope.function_cidr_to_netmask([cidr]).should == netmask
  end
end