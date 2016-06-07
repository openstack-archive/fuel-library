require 'yaml'
require 'spec_helper'

describe 'filter_nodes_with_enabled_option' do
  let(:compute_nodes_yaml) do
  <<-eof
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
eof
  end

  let(:compute_nodes) do
    YAML.load(compute_nodes_yaml)
  end

  before(:each) do
    puppet_debug_override
  end

  it 'should exist' do
    is_expected.not_to be_nil
  end

  it 'should fail if wrong argument count given' do
    is_expected.to run.with_params({'node-1'=>{'uid'=>'1'}}, 'nova_hugepages_enabled', 'eee').and_raise_error(Puppet::ParseError, /takes exactly 2 arguments/)
    is_expected.to run.with_params().and_raise_error(Puppet::ParseError, /takes exactly 2 arguments/)
  end

  it 'should fail if the first argument is not a hash' do
    is_expected.to run.with_params(['node-1'],'eee').and_raise_error(Puppet::ParseError, /must be a hash/)
  end

  it 'should fail if the second argument is not a string' do
    is_expected.to run.with_params({'node-1'=>{'uid'=>'1'}}, ['fqdn']).and_raise_error(Puppet::ParseError, /must be a string/)
  end

  it 'should return array of nodes fqdn with nova_hugepages_enabled' do
    is_expected.to run.with_params(compute_nodes, 'nova_hugepages_enabled').and_return(['node-1.test.domain.local','node-2.test.domain.local'])
  end

  it 'should return array of nodes fqdn with nova_cpu_pinning_enabled' do
    is_expected.to run.with_params(compute_nodes, 'nova_cpu_pinning_enabled').and_return(['node-2.test.domain.local','node-3.test.domain.local'])
  end

  it 'should return empty array when missing option is specified' do
    is_expected.to run.with_params(compute_nodes, 'abc').and_return([])
  end

end
