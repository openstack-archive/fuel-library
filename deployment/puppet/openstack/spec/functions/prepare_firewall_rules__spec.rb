require 'puppet'
require 'spec_helper'

describe 'prepare_firewall_rules' do

  describe 'basic tests' do

    it 'should exist' do
      is_expected.not_to be_nil
    end

    it 'error if no arguments' do
      is_expected.to run.with_params().and_raise_error(ArgumentError)
    end

    it 'should require six arguments' do
      is_expected.to run.with_params('a','b','c','d','e','f','g').and_raise_error(ArgumentError)
    end

    it 'should require rule_basename to be a string' do
      is_expected.to run.with_params(['0.0.0.0/0'],{'hash' => 'notastring'},nil,nil,nil,nil)
                         .and_raise_error(ArgumentError, /rule_basename is not a string/)
    end

    it 'should require source_nets to be an array of strings' do
      is_expected.to run.with_params(['0.0.0.0/0', nil],'020 ssh',nil,nil,nil,nil)
                         .and_raise_error(ArgumentError, /source_net is not an array of strings/)
    end

    it 'should be able to prepare an ssh rule' do
      result = {
        '020 ssh from 10.0.0.0/24' => {'action' => 'accept',
                                      'dport'   => '22',
                                      'proto'  => 'tcp',
                                      'source' => '10.0.0.0/24'},
        '020 ssh from 10.0.1.0/24' => {'action' => 'accept',
                                      'dport'   => '22',
                                      'proto'  => 'tcp',
                                      'source' => '10.0.1.0/24'},
      }
      is_expected.to run.with_params(['10.0.0.0/24','10.0.1.0/24'],'020 ssh', 'accept', nil, '22', 'tcp').and_return(result)
    end

  end
end

