require 'spec_helper'

describe 'the amqp_hosts function' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it 'should exist' do
    expect(
        Puppet::Parser::Functions.function('amqp_hosts')
    ).to eq('function_amqp_hosts')
  end

  it 'should raise an error if there is less than 1 arguments' do
    expect {
      scope.function_amqp_hosts([])
    }.to raise_error StandardError
  end

  it 'should convert the array on nodes to host:port pairs' do
    scope.expects(:lookupvar).with('::fqdn', {}).returns('127.0.0.1')
    hosts = scope.function_amqp_hosts([%w(192.168.0.1 192.168.0.2 192.168.0.3), '5673'])
    expect(hosts.split(', ').sort).to eq %w(192.168.0.1:5673 192.168.0.2:5673 192.168.0.3:5673)
  end

  it 'should use port 5673 by default if it was not provided' do
    scope.expects(:lookupvar).with('::fqdn', {}).returns('127.0.0.1')
    hosts = scope.function_amqp_hosts([%w(192.168.0.1 192.168.0.2 192.168.0.3)])
    expect(hosts.split(', ').sort).to eq %w(192.168.0.1:5673 192.168.0.2:5673 192.168.0.3:5673)
  end

  it 'should use different order for different fqdns' do
    scope.expects(:lookupvar).with('::fqdn', {}).returns('192.168.0.1')
    hosts = scope.function_amqp_hosts([%w(192.168.0.1 192.168.0.2 192.168.0.3), '5673'])
    expect(hosts.split(', ').sort).to eq %w(192.168.0.1:5673 192.168.0.2:5673 192.168.0.3:5673)
  end

  it 'should be able to use another port value' do
    scope.expects(:lookupvar).with('::fqdn', {}).returns('127.0.0.1')
    hosts = scope.function_amqp_hosts([%w(192.168.0.1 192.168.0.2 192.168.0.3), '123'])
    expect(hosts.split(', ').sort).to eq %w(192.168.0.1:123 192.168.0.2:123 192.168.0.3:123)
  end

  it 'should move prefered host to the first place if i was found in the list' do
    scope.expects(:lookupvar).with('::fqdn', {}).returns('127.0.0.1')
    hosts = scope.function_amqp_hosts([%w(192.168.0.1 192.168.0.2 192.168.0.3), '5673', '192.168.0.3'])
    expect(hosts.split(', ')).to eq %w(192.168.0.3:5673 192.168.0.1:5673 192.168.0.2:5673)
  end

  it 'should ignore prefered host if it is not in the list' do
    scope.expects(:lookupvar).with('::fqdn', {}).returns('127.0.0.1')
    hosts = scope.function_amqp_hosts([%w(192.168.0.1 192.168.0.2 192.168.0.3), '5673', '172.16.0.1'])
    expect(hosts.split(', ').sort).to eq %w(192.168.0.1:5673 192.168.0.2:5673 192.168.0.3:5673)
  end

  it 'should be able to work with comma separated host list' do
    scope.expects(:lookupvar).with('::fqdn', {}).returns('127.0.0.1')
    hosts = scope.function_amqp_hosts(['192.168.0.1, 192.168.0.2,192.168.0.3', '5673'])
    expect(hosts.split(', ').sort).to eq %w(192.168.0.1:5673 192.168.0.2:5673 192.168.0.3:5673)
  end

  it 'should be able to work with a single host' do
    expect(
        scope.function_amqp_hosts(['192.168.0.1', '5673'])
    ).to eq '192.168.0.1:5673'
  end

  it 'should not spoil the input data' do
    hosts = %w(192.168.0.1 192.168.0.2 192.168.0.3)
    amqp_hosts = scope.function_amqp_hosts([hosts])
    expect(hosts).to eq(%w(192.168.0.1 192.168.0.2 192.168.0.3))
  end

end
