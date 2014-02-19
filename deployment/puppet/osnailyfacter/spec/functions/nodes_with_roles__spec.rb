require 'spec_helper'

describe 'nodes_with_roles' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it 'should exist' do
    Puppet::Parser::Functions.function('nodes_with_roles').should == 'function_nodes_with_roles'
  end

  it 'should return array of matching nodes' do
    scope.function_nodes_with_roles(
      [
        {
          'uid' => 1,
          'role' => 'role1',
        },
        {
          'uid' => 2,
          'role' => 'role2',
        },
        {
          'uid' => 3,
          'role' => 'role3',
        }
      ],
      ['role1', 'role2']
    ).should == [
        {
          'uid' => 1,
          'role' => 'role1',
        },
        {
          'uid' => 2,
          'role' => 'role2',
        }
    ]
  end

  it 'should eliminate duplicate uids' do
    scope.function_nodes_with_roles(
      [
        {
          'uid' => 1,
          'role' => 'role1',
        },
        {
          'uid' => 1,
          'role' => 'role2',
        },
        {
          'uid' => 2,
          'role' => 'role3',
        }
      ],
      ['role1', 'role2'],
      'uid'
    ).should == [1]
  end
end
