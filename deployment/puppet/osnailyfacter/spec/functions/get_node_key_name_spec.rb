require 'spec_helper'

describe 'get_node_key_name' do
  it 'should exist' do
    is_expected.not_to be_nil
  end

  it 'should be able to calculate node key name' do
    scope.stubs(:function_hiera).with(['uid']).returns('121')
    scope.stubs(:call_function).with('hiera', 'uid').returns('121')
    is_expected.to run.with_params().and_return('node-121')
  end

  it 'should raise error if UID not given' do
    scope.stubs(:function_hiera).with(['uid']).returns(nil)
    scope.stubs(:call_function).with('hiera', 'uid').returns(nil)
    is_expected.to run.with_params().and_raise_error(Puppet::ParseError)
  end

end
