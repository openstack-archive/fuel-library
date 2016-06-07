require 'spec_helper'

describe 'amqp_hosts' do

  it 'should exist' do
    is_expected.not_to be_nil
  end

  it 'should raise an error if there is less than 1 arguments' do
    is_expected.to run.with_params().and_raise_error(Puppet::ParseError)
  end

  let (:host) { '127.0.0.1' }
  let (:other_host) { '127.0.0.2' }

  before(:each) do
    #scope.stubs(:lookupvar).with('::fqdn', {}).returns('127.0.0.1')
    scope.stubs(:[]).with("::fqdn").returns(host)
  end

  it 'should have hostname equal to host variable' do
    is_expected.to 
  end
  
  it 'should convert the array on nodes to host:port pairs' do
    is_expected.to run.with_params(%w(192.168.0.1 192.168.0.2 192.168.0.3), '5673')
                       .and_return('192.168.0.1:5673, 192.168.0.2:5673, 192.168.0.3:5673')
  end

  it 'should use port 5673 by default if it was not provided' do
    is_expected.to run.with_params(%w(192.168.0.1 192.168.0.2 192.168.0.3))
                       .and_return('192.168.0.1:5673, 192.168.0.2:5673, 192.168.0.3:5673')
  end

  it 'should use different order for different fqdns' do
    #scope.stubs(:lookupvar).with('::fqdn', {}).returns('127.0.0.2')
    scope.stubs(:[]).with("::fqdn").returns(other_host)
    is_expected.to run.with_params(%w(192.168.0.1 192.168.0.2 192.168.0.3), '5673')
                       .and_return('192.168.0.2:5673, 192.168.0.3:5673, 192.168.0.1:5673')
  end
  
  it 'should be able to use another port value' do
    is_expected.to run.with_params(%w(192.168.0.1 192.168.0.2 192.168.0.3), '123')
                       .and_return('192.168.0.1:123, 192.168.0.2:123, 192.168.0.3:123')
  end

  it 'should move prefered host to the first place if i was found in the list' do
    #scope.stubs(:lookupvar).with('::fqdn', {}).returns('127.0.0.2')
    scope.stubs(:[]).with("::fqdn").returns(other_host)
    is_expected.to run.with_params(%w(192.168.0.1 192.168.0.2 192.168.0.3), '5673', '192.168.0.3')
                       .and_return('192.168.0.3:5673, 192.168.0.2:5673, 192.168.0.1:5673')
  end

  it 'should ignore prefered host if it is not in the list' do
    #scope.stubs(:lookupvar).with('::fqdn', {}).returns('127.0.0.2')
    scope.stubs(:[]).with("::fqdn").returns(other_host)
    is_expected.to run.with_params(%w(192.168.0.1 192.168.0.2 192.168.0.3), '5673', '172.16.0.1')
                       .and_return('192.168.0.2:5673, 192.168.0.3:5673, 192.168.0.1:5673')
  end

  it 'should be able to work with comma-separated host list' do
    is_expected.to run.with_params('192.168.0.1, 192.168.0.2,192.168.0.3', '5673')
                       .and_return('192.168.0.1:5673, 192.168.0.2:5673, 192.168.0.3:5673')
  end

  it 'should be able to work with a single host' do
    is_expected.to run.with_params('192.168.0.1', '5673')
                       .and_return('192.168.0.1:5673')
  end

  it 'should not spoil the input data' do
    hosts = %w(192.168.0.1 192.168.0.2 192.168.0.3)
    is_expected.not_to run.with_params(%w(192.168.0.1 192.168.0.2 192.168.0.3))
                       .and_raise_error(Puppet::Error)
    expect(hosts).to eq(%w(192.168.0.1 192.168.0.2 192.168.0.3))
  end

end
