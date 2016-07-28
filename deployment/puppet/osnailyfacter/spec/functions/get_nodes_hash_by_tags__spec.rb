require 'spec_helper'
require 'yaml'

describe Puppet::Parser::Functions.function(:get_nodes_hash_by_tags) do
let(:network_metadata) do
YAML.load("
---
  nodes:
    node-55:
      node_tags:
        - controller
        - mongo
        - cinder
    node-66:
      node_tags:
        - compute
        - cinder
        - xxx
        - yyy
    node-77:
      node_tags:
        - mongo
        - cinder
        - xxx
")
end

  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  subject do
    function_name = Puppet::Parser::Functions.function(:get_nodes_hash_by_tags)
    scope.method(function_name)
  end

  context "get_nodes_hash_by_tags($nodes_hash, ['tag1','tag2']) usage" do

    it 'should exist' do
      subject == Puppet::Parser::Functions.function(:get_nodes_hash_by_tags)
    end

    it 'should return nodes hash for "controller" tag' do
      rv = scope.function_get_nodes_hash_by_tags([network_metadata, ['controller']])
      rv.keys.sort.should == ['node-55']
    end

    it 'should return nodes hash for "mongo" tag' do
      rv = scope.function_get_nodes_hash_by_tags([network_metadata, ['mongo']])
      rv.keys.sort.should == ['node-55', 'node-77']
    end

    it 'should return nodes hash for "cinder" tag' do
      rv = scope.function_get_nodes_hash_by_tags([network_metadata, ['cinder']])
      rv.keys.sort.should == ['node-55', 'node-66', 'node-77']
    end

    it 'should return nodes hash for "controller"+"xxx" tag' do
      rv = scope.function_get_nodes_hash_by_tags([network_metadata, ['controller', 'xxx']])
      rv.keys.sort.should == ['node-55', 'node-66', 'node-77']
    end

    it 'should return nodes hash for "controller"+"yyy" tag' do
      rv = scope.function_get_nodes_hash_by_tags([network_metadata, ['controller', 'yyy']])
      rv.keys.sort.should == ['node-55', 'node-66']
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
