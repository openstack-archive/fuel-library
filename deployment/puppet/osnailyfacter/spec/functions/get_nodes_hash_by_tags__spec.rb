require 'spec_helper'
require 'yaml'

describe 'get_nodes_hash_by_tags' do
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

  it 'should exist' do
    is_expected.not_to be_nil
  end

  context "get_nodes_hash_by_tags($nodes_hash, ['role1','role2']) usage" do

    it 'should return nodes hash for "controller" tag' do
      is_expected.to run.with_params(network_metadata, ['controller']).and_return(
          {
              "node-55" => {
                  "node_tags" => ["controller", "mongo", "cinder"],
              }
          }
      )
    end

    it 'should return nodes hash for "mongo" tag' do
      is_expected.to run.with_params(network_metadata, ['mongo']).and_return(
          {
              "node-55" => {
                  "node_tags" => ["controller", "mongo", "cinder"],
              },
              "node-77" => {
                  "node_tags" => ["mongo", "cinder", "xxx"],
              },
          }
      )
    end

    it 'should return nodes hash for "cinder" tag' do
      is_expected.to run.with_params(network_metadata, ['cinder']).and_return(
          {
              "node-55" => {
                  "node_tags" => ["controller", "mongo", "cinder"]
              },
              "node-66" => {
                  "node_tags" => ["compute", "cinder", "xxx", "yyy"]
              },
              "node-77" => {
                  "node_tags" => ["mongo", "cinder", "xxx"]
              }
          }
      )
    end

    it 'should return nodes hash for "controller"+"xxx" tag' do
      is_expected.to run.with_params(network_metadata, ['controller', 'xxx']).and_return(
          {
              "node-55" => {
                  "node_tags" => ["controller", "mongo", "cinder"]
              },
              "node-66" => {
                  "node_tags" => ["compute", "cinder", "xxx", "yyy"]
              },
              "node-77" => {
                  "node_tags" => ["mongo", "cinder", "xxx"]
              }
          }
      )
    end

    it 'should return nodes hash for "controller"+"yyy" tag' do
      is_expected.to run.with_params(network_metadata, ['controller', 'yyy']).and_return(
          {
              "node-55" => {
                  "node_tags" => ["controller", "mongo", "cinder"]
              },
              "node-66" => {
                  "node_tags" => ["compute", "cinder", "xxx", "yyy"]
              },
          }
      )
    end

    it 'should raise Puppet::ParseError if 1st argument not a Hash' do
      is_expected.to run.with_params('xxx', ['controller', 'yyy']).and_raise_error(Puppet::ParseError)
    end

    it 'should raise Puppet::ParseError if 1st argument has wrong format' do
      is_expected.to run.with_params({:a => 1, :b => 2}, ['controller', 'yyy']).and_raise_error(Puppet::ParseError)
    end

    it 'should raise Puppet::ParseError if 2nd argument not an array' do
      is_expected.to run.with_params(network_metadata, 'cinder').and_raise_error(Puppet::ParseError)
    end

  end

end
