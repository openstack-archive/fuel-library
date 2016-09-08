require 'spec_helper'

describe 'cidr_to_netmask' do

  it 'should exist' do
    is_expected.not_to be_nil
  end

  it 'should throw an error on invalid types' do
    is_expected.to run.with_params({:foo => :bar}).and_raise_error(Puppet::ParseError)
  end

  it 'should throw an error on invalid CIDR' do
    invalid_cidrs = ['192.168.33.66', '192.256.33.66/23', 'jhgjhgghggh']
    for cidr in invalid_cidrs
      is_expected.to run.with_params(cidr).and_raise_error(Puppet::ParseError)
    end
  end

  it 'should throw an error on invalid CIDR masklen' do
    cidr = '192.168.33.66/33'
    is_expected.to run.with_params(cidr).and_raise_error(Puppet::ParseError)
  end

  it 'should return netmask from CIDR' do
    cidr = '192.168.33.66/25'
    netmask = '255.255.255.128'
    is_expected.to run.with_params(cidr).and_return(netmask)
  end
end
