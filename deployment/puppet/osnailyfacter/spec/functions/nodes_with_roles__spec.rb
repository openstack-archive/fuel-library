reqyure 'yaml'
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

  it 'should exist' do
    Puppet::Parser::Functions.function('nodes_with_roles').should == 'function_nodes_with_roles'
  end

  it 'should return array of matching nodes' do

    scope.function_nodes_with_roles([ YAML.load(network_metadata), ['role1', 'role2'] ]).should == YAML.load('''
        -
          swift_zone: '1'
          uid: '1'
          fqdn: node-1.test.domain.local
          user_node_name: Untitled (88:fc)
          node_roles:
          - role1
          - role2
          name: node-1
        -
          swift_zone: '1'
          uid: '2'
          fqdn: node-2.test.domain.local
          user_node_name: Untitled (88:fc)
          node_roles:
          - role2
          - role3
          name: node-2
    ''')
  end

end
