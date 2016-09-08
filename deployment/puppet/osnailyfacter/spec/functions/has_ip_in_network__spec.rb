require 'spec_helper'

describe 'has_ip_in_network' do

  it 'should exist' do
    is_expected.not_to be_nil
  end

  it 'should throw an error on invalid arguments number' do
    is_expected.to run.with_params('foo').and_raise_error(ArgumentError)
  end

  it 'should raise an error if invalid address or network is specified' do
    is_expected.to run.with_params('foo', 'bar').and_raise_error(Puppet::ParseError)
  end

  it 'should return true if IP address is from CIDR' do
    cidr = '192.168.0.0/16'
    ipaddr = '192.168.33.66'
    is_expected.to run.with_params(ipaddr, cidr).and_return(true)
  end

  it 'should return false if IP address is not from CIDR' do
    cidr = '192.168.0.0/255.255.0.0'
    ipaddr = '172.16.0.1'
    is_expected.to run.with_params(ipaddr, cidr).and_return(false)
  end

end
