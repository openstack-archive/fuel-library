require 'spec_helper'

describe 'the get_node_key_name function' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it 'should exist' do
    expect(
        Puppet::Parser::Functions.function('get_node_key_name')
    ).to eq('function_get_node_key_name')
  end

  it 'should be able to calculate node key name' do
    scope.stubs(:function_hiera).with(['uid']).returns('121')
    scope.stubs(:call_function).with('hiera', 'uid').returns('121')
    expect(scope.function_get_node_key_name []).to eq 'node-121'
  end

  it 'should raise error if UID not gived' do
    scope.stubs(:function_hiera).with(['uid']).returns(nil)
    scope.stubs(:call_function).with('hiera', 'uid').returns(nil)
    expect{scope.function_get_node_key_name []}.to raise_error(Puppet::ParseError)
  end

end
