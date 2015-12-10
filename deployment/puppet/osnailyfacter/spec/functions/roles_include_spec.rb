require 'spec_helper'

describe 'the roles_include function' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it 'should exist' do
    expect(
        Puppet::Parser::Functions.function('roles_include')
    ).to eq('function_roles_include')
  end

  it 'should raise an error if there is less than 1 arguments' do
    expect {
      scope.function_roles_include([])
    }.to raise_error /Wrong number of arguments/
  end

  before(:each) do
    scope.stubs(:function_hiera).with(['nodes']).returns(
      [
          {
              'uid' => '1',
              'role' => 'controller',
          },
          {
              'uid' => '2',
              'role' => 'compute',
          },
          {
              'uid' => '2',
              'role' => 'ceph',
          },
      ]
    )
  end

  it 'should be able to find a matching role' do
    scope.stubs(:function_hiera).with(['uid']).returns('1')
    expect(
        scope.function_roles_include [ 'controller' ]
    ).to eq true
    expect(
        scope.function_roles_include [ %w(controller primary-controller) ]
    ).to eq true
  end

  it 'should be able to find a non-matching role' do
    scope.stubs(:function_hiera).with(['uid']).returns('1')
    expect(
        scope.function_roles_include [ 'compute' ]
    ).to eq false
    scope.stubs(:function_hiera).with(['uid']).returns('2')
    expect(
        scope.function_roles_include [ 'controller' ]
    ).to eq false
  end

end
