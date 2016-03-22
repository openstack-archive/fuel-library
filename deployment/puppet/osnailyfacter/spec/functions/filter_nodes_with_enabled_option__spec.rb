require 'yaml'
require 'spec_helper'

describe 'filter_nodes_with_enabled_option' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }
  let(:compute_nodes) do
  YAML.load("
---
  node-1:
    swift_zone: '1'
    uid: '1'
    fqdn: node-1.test.domain.local
    node_roles:
    - compute
    name: node-1
    nova_hugepages_enabled: true
  node-2:
    swift_zone: '1'
    uid: '2'
    fqdn: node-2.test.domain.local
    node_roles:
    - compute
    name: node-2
    nova_hugepages_enabled: true
    nova_cpu_pinning_enabled: true
  node-3:
    swift_zone: '1'
    uid: '3'
    fqdn: node-3.test.domain.local
    node_roles:
    - compute
    name: node-3
    nova_cpu_pinning_enabled: true
  ")
  end

  before(:each) do
    puppet_debug_override()
  end

  it 'should exist' do
    expect(Puppet::Parser::Functions.function('filter_nodes_with_enabled_option')).to eq('function_filter_nodes_with_enabled_option')
  end

  it 'should fail if wrong argument count given' do
    expect{scope.function_filter_nodes_with_enabled_option([{'node-1'=>{'uid'=>'1'}}, 'nova_hugepages_enabled', 'eee'])}.to raise_error(Puppet::ParseError, /takes exactly 2 arguments/)
    expect{scope.function_filter_nodes_with_enabled_option([])}.to raise_error(Puppet::ParseError, /takes exactly 2 arguments/)
  end

  it 'should fail if the first argument is not a hash' do
    expect{scope.function_filter_nodes_with_enabled_option([['node-1'],'eee'])}.to raise_error(Puppet::ParseError, /must be a hash/)
  end

  it 'should fail if the second argument is not a string' do
    expect{scope.function_filter_nodes_with_enabled_option([{'node-1'=>{'uid'=>'1'}}, ['fqdn']])}.to raise_error(Puppet::ParseError, /must be a string/)
  end

  it 'should return array of nodes fqdn with nova_hugepages_enabled' do
    expect(scope.function_filter_nodes_with_enabled_option([compute_nodes, 'nova_hugepages_enabled'])).to eq(['node-1.test.domain.local','node-2.test.domain.local'])
  end

  it 'should return array of nodes fqdn with nova_cpu_pinning_enabled' do
    expect(scope.function_filter_nodes_with_enabled_option([compute_nodes, 'nova_cpu_pinning_enabled'])).to eq(['node-2.test.domain.local','node-3.test.domain.local'])
  end

  it 'should return empty array when missing option is specified' do
    expect(scope.function_filter_nodes_with_enabled_option([compute_nodes, 'abc'])).to eq([])
  end

end
