require 'spec_helper'

describe 'the get_node_short_name function' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it 'should exist' do
    expect(
        Puppet::Parser::Functions.function('get_node_short_name')
    ).to eq('function_get_node_short_name')
  end

  it 'should be able to find a node_name for long name' do
    scope.stubs(:function_hiera).with(['fqdn', nil]).returns('qwe.subdomain.domain.tld')
    expect(scope.function_get_node_short_name []).to eq 'qwe'
  end

  it 'should be able to find a node_name for long name' do
    scope.stubs(:function_hiera).with(['fqdn', nil]).returns('qwe')
    expect(scope.function_get_node_short_name []).to eq 'qwe'
  end

  it 'should be able to find a node_name for long name' do
    scope.stubs(:function_hiera).with(['fqdn', 'lll.localhost.tld']).returns('lll.localhost.tld')
    scope.stubs(:lookupvar).with('fqdn').returns('lll.localhost.tld')
    expect(scope.function_get_node_short_name []).to eq 'lll'
  end

end
