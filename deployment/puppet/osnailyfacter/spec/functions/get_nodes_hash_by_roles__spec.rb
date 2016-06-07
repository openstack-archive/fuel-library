require 'spec_helper'
require 'yaml'

describe 'get_nodes_hash_by_roles' do
  let(:network_metadata_yaml) do
    <<-eof
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
    eof
  end

  let(:network_metadata) do
    YAML.load(network_metadata_yaml)
  end

  it 'should exist' do
    is_expected.not_to be_nil
  end

  context "get_nodes_hash_by_roles($nodes_hash, ['role1','role2']) usage" do

    it 'should return nodes hash for "controller" role' do
      is_expected.to run.with_params(network_metadata, ['controller']).and_return(
          {
              "node-55" => {
                  "node_roles" => ["controller", "mongo", "cinder"],
              }
          }
      )
    end

    it 'should return nodes hash for "mongo" role' do
      is_expected.to run.with_params(network_metadata, ['mongo']).and_return(
          {
              "node-55" => {
                  "node_roles" => ["controller", "mongo", "cinder"],
              },
              "node-77" => {
                  "node_roles" => ["mongo", "cinder", "xxx"],
              },
          }
      )
    end

    it 'should return nodes hash for "cinder" role' do
      is_expected.to run.with_params(network_metadata, ['cinder']).and_return(
          {
              "node-55" => {
                  "node_roles" => ["controller", "mongo", "cinder"]
              },
              "node-66" => {
                  "node_roles" => ["compute", "cinder", "xxx", "yyy"]
              },
              "node-77" => {
                  "node_roles" => ["mongo", "cinder", "xxx"]
              }
          }
      )
    end

    it 'should return nodes hash for "controller"+"xxx" role' do
      is_expected.to run.with_params(network_metadata, ['controller', 'xxx']).and_return(
          {
              "node-55" => {
                  "node_roles" => ["controller", "mongo", "cinder"]
              },
              "node-66" => {
                  "node_roles" => ["compute", "cinder", "xxx", "yyy"]
              },
              "node-77" => {
                  "node_roles" => ["mongo", "cinder", "xxx"]
              }
          }
      )
    end

    it 'should return nodes hash for "controller"+"yyy" role' do
      is_expected.to run.with_params(network_metadata, ['controller', 'yyy']).and_return(
          {
              "node-55" => {
                  "node_roles" => ["controller", "mongo", "cinder"]
              },
              "node-66" => {
                  "node_roles" => ["compute", "cinder", "xxx", "yyy"]
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
