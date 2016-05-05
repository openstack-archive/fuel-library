require 'spec_helper'

describe 'cidr_to_ipaddr' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it 'should exist' do
    expect(Puppet::Parser::Functions.function('cidr_to_ipaddr')).to eq 'function_cidr_to_ipaddr'
  end

  it 'should throw an error on invalid types' do
    expect do
      scope.function_cidr_to_ipaddr([{:foo => :bar}])
    end.to raise_error(Puppet::ParseError)
  end

  it 'should throw an error on invalid CIDR' do
    invalid_cidrs = ['192.168.33.66', '192.256.33.66/23', 'jhgjhgghggh']
    for cidr in invalid_cidrs
      expect do
        scope.function_cidr_to_ipaddr([cidr])
      end.to raise_error(Puppet::ParseError)
    end
  end

  it 'should throw an error on invalid CIDR masklen' do
    cidr = '192.168.33.66/33'
    expect do
      scope.function_cidr_to_ipaddr([cidr])
    end.to raise_error(Puppet::ParseError)
  end

  it 'should return IP address from CIDR' do
    cidr = '192.168.33.66/25'
    ipaddr = '192.168.33.66'
    expect(scope.function_cidr_to_ipaddr([cidr])).to eq ipaddr
  end
end
