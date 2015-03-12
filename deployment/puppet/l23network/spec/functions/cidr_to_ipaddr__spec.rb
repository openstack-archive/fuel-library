require 'spec_helper'

describe 'cidr_to_ipaddr' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it 'should exist' do
    Puppet::Parser::Functions.function('cidr_to_ipaddr').should == 'function_cidr_to_ipaddr'
  end

  it 'should throw an error on invalid types' do
    lambda {
      scope.function_cidr_to_ipaddr([{:foo => :bar}])
    }.should(raise_error(Puppet::ParseError))
  end

  it 'should throw an error on invalid CIDR' do
    invalid_cidrs = ['192.168.33.66', '192.256.33.66/23', 'jhgjhgghggh']
    for cidr in invalid_cidrs
	    lambda {
	      scope.function_cidr_to_ipaddr([cidr])
	    }.should(raise_error(Puppet::ParseError))
    end
  end

  it 'should throw an error on invalid CIDR masklen' do
    cidr = '192.168.33.66/33'
    lambda {
      scope.function_cidr_to_ipaddr([cidr])
    }.should(raise_error(Puppet::ParseError))
  end

  it 'should return IP address from CIDR' do
    cidr = '192.168.33.66/25'
    ipaddr = '192.168.33.66'
    scope.function_cidr_to_ipaddr([cidr]).should == ipaddr
  end
end