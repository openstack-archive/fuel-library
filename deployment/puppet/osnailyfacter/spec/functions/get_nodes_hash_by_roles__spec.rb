require 'spec_helper'
require 'yaml'

describe Puppet::Parser::Functions.function(:get_nodes_hash_by_roles) do
let(:network_metadata) do
YAML.load("
---
  nodes:
    node-55:
      node_roles:
        - controller
        - mongo
        - cinder
    node-66:
      node_roles:
        - compute
        - cinder
        - xxx
        - yyy
    node-77:
      node_roles:
        - mongo
        - cinder
        - xxx
")
end

  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  subject do
    function_name = Puppet::Parser::Functions.function(:get_nodes_hash_by_roles)
    scope.method(function_name)
  end

  context "get_nodes_hash_by_roles($nodes_hash, ['role1','role2']) usage" do

    it 'should exist' do
      subject == Puppet::Parser::Functions.function(:get_nodes_hash_by_roles)
    end

    it 'should return nodes hash for "controller" role' do
      rv = scope.function_get_nodes_hash_by_roles([network_metadata, ['controller']])
      expect(rv.keys.sort).to eq ['node-55']
    end

    it 'should return nodes hash for "mongo" role' do
      rv = scope.function_get_nodes_hash_by_roles([network_metadata, ['mongo']])
      expect(rv.keys.sort).to eq ['node-55', 'node-77']
    end

    it 'should return nodes hash for "cinder" role' do
      rv = scope.function_get_nodes_hash_by_roles([network_metadata, ['cinder']])
      expect(rv.keys.sort).to eq ['node-55', 'node-66', 'node-77']
    end

    it 'should return nodes hash for "controller"+"xxx" role' do
      rv = scope.function_get_nodes_hash_by_roles([network_metadata, ['controller', 'xxx']])
      expect(rv.keys.sort).to eq ['node-55', 'node-66', 'node-77']
    end

    it 'should return nodes hash for "controller"+"yyy" role' do
      rv = scope.function_get_nodes_hash_by_roles([network_metadata, ['controller', 'yyy']])
      expect(rv.keys.sort).to eq ['node-55', 'node-66']
    end

    it 'should raise Puppet::ParseError if 1st argument not a Hash' do
      should run.with_params('xxx', ['controller', 'yyy']).and_raise_error(Puppet::ParseError)
    end

    it 'should raise Puppet::ParseError if 1st argument has wrong format' do
      should run.with_params({:a=>1, :b=>2}, ['controller', 'yyy']).and_raise_error(Puppet::ParseError)
    end

    it 'should raise Puppet::ParseError if 2nd argument not an array' do
      should run.with_params(network_metadata, 'cinder').and_raise_error(Puppet::ParseError)
    end

  end

end
