require 'yaml'
require 'spec_helper'

describe 'nodes_with_roles' do

  let(:network_metadata) do
    <<-eof
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
    is_expected.not_to be_nil
  end

  before(:each) do
    scope.stubs(:function_hiera_hash).with(['network_metadata', {}]).returns(YAML.load(network_metadata))
    scope.stubs(:call_function).with('hiera_hash', 'network_metadata').returns(YAML.load(network_metadata))
  end

  it 'should exist' do
    is_expected.not_to be_nil
  end

  it 'should be fail if wrong argument count given' do
    is_expected.to run.with_params(%w(role1 role2), 'fqdn', 'eee').and_raise_error(Puppet::ParseError)
    is_expected.to run.with_params().and_raise_error(Puppet::ParseError)
  end

  it 'should be fail if roles given not as array' do
    is_expected.to run.with_params('role1').and_raise_error(Puppet::ParseError)
  end

  it 'should be fail if additional attribute given not as string' do
    is_expected.to run.with_params(%w(role1 role2), %w(fqdn eee)).and_raise_error(Puppet::ParseError)
  end

  it 'should return array of matching nodes' do
    nodes = <<-eof
        - swift_zone: "1"
          uid: "1"
          fqdn: node-1.test.domain.local
          user_node_name: Untitled (88:fc)
          node_roles:
          - role1
          - role2
          name: node-1
        - swift_zone: "1"
          uid: "2"
          fqdn: node-2.test.domain.local
          user_node_name: Untitled (88:fc)
          node_roles:
          - role2
          - role3
          name: node-2
    eof

    is_expected.to run.with_params(%w(role1 role2)).and_return(YAML.load(nodes))
  end

  it 'should return array of nodes fqdn' do
    is_expected.to run.with_params(%w(role1 role2), 'fqdn').and_return(%w(node-1.test.domain.local node-2.test.domain.local))
  end

end
