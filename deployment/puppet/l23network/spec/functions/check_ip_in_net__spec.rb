require 'spec_helper'

describe 'check_ip_in_net' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it 'should exist' do
    Puppet::Parser::Functions.function('check_ip_in_net').should == 'function_check_ip_in_net'
  end

  it 'should throw an error on invalid arguments number' do
    lambda {
      scope.function_check_ip_in_net(['foo'])
    }.should(raise_error(ArgumentError))
  end

  it 'should return true if IP address is from CIDR' do
    cidr = '192.168.0.0/16'
    ipaddr = '192.168.33.66'
    scope.function_check_ip_in_net([ipaddr, cidr]).should == true
  end

  it 'should return false if IP address is not from CIDR' do
    cidr = '192.168.0.0/255.255.0.0'
    ipaddr = '172.16.0.1'
    scope.function_check_ip_in_net([ipaddr, cidr]).should == false
  end

end
