require 'spec_helper'

describe 'get_route_resource_name' do

  it 'should exist' do
    is_expected.not_to be_nil
  end

  it 'should throw an error if called without args' do
    is_expected.to run.with_params().and_raise_error(Puppet::ParseError)
  end

  it 'should throw an error if called with more two args' do
    is_expected.to run.with_params('192.168.2.0/24', 10, 20).and_raise_error(Puppet::ParseError)
  end

  it do
    is_expected.to run.with_params('192.168.2.0/24').and_return('192.168.2.0/24')
  end

  it do
    is_expected.to run.with_params('192.168.2.0/24', 10).and_return('192.168.2.0/24,metric:10')
  end

  it do
    is_expected.to run.with_params('192.168.2.0/24', 'xxx').and_return('192.168.2.0/24')
  end
  
end
