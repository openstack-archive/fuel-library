require 'yaml'
require 'spec_helper'

describe 'nodes_with_roles' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }
  let(:network_metadata) do
  <<eof
---
nodes:
  node-1:
    swift_zone: '1'
    uid: '1'
    fqdn: node-1.test.domain.local
    user_node_name: Untitled (88:fc)
    node_roles:
    - role1
    - role2
    name: node-1
  node-2:
    swift_zone: '1'
    uid: '2'
    fqdn: node-2.test.domain.local
    user_node_name: Untitled (88:fc)
    node_roles:
    - role2
    - role3
    name: node-2
  node-3:
    swift_zone: '1'
    uid: '3'
    fqdn: node-3.test.domain.local
    user_node_name: Untitled (88:fc)
    node_roles:
    - role3
    - role4
    name: node-3
eof
  end

  before(:each) do
    puppet_debug_override()
  end

  before(:each) do
    scope.stubs(:function_hiera_hash).with(['network_metadata', {}]).returns(YAML.load(network_metadata))
  end

  it 'should exist' do
    expect(Puppet::Parser::Functions.function('nodes_with_roles')).to eq('function_nodes_with_roles')
  end

  it 'should be fail if wrong argument count given' do
    expect{scope.function_nodes_with_roles([['role1', 'role2'], 'fqdn', 'eee'])}.to raise_error(Puppet::ParseError)
    expect{scope.function_nodes_with_roles([])}.to raise_error(Puppet::ParseError)
  end

  it 'should be fail if roles given not as array' do
    expect{scope.function_nodes_with_roles(['role1'])}.to raise_error(Puppet::ParseError)
  end

  it 'should be fail if additional attribute given not as string' do
    expect{scope.function_nodes_with_roles([['role1', 'role2'], ['fqdn', 'eee']])}.to raise_error(Puppet::ParseError)
  end

  it 'should return array of matching nodes' do
    expect(scope.function_nodes_with_roles([['role1', 'role2']])).to eq(YAML.load('''
        -
          swift_zone: "1"
          uid: "1"
          fqdn: node-1.test.domain.local
          user_node_name: Untitled (88:fc)
          node_roles:
          - role1
          - role2
          name: node-1
        -
          swift_zone: "1"
          uid: "2"
          fqdn: node-2.test.domain.local
          user_node_name: Untitled (88:fc)
          node_roles:
          - role2
          - role3
          name: node-2
    '''))
  end

  it 'should return array of nodes fqdn' do
    expect(scope.function_nodes_with_roles([['role1', 'role2'], 'fqdn'])).to eq(['node-1.test.domain.local','node-2.test.domain.local'])
  end

end
