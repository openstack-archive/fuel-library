require 'puppet'
require 'spec_helper'

describe 'function to prepare hash of firewall rules for multiple networks' do

  def setup_scope
    @compiler = Puppet::Parser::Compiler.new(Puppet::Node.new("floppy", :environment => 'production'))
    @scope = Puppet::Parser::Scope.new(@compiler)
    @topscope = @topscope
    @scope.parent = @topscope
    Puppet::Parser::Functions.function(:prepare_firewall_rules)
  end

  describe 'basic tests' do

    before :each do
      setup_scope
    end

    it "should exist" do
      Puppet::Parser::Functions.function(:prepare_firewall_rules).should == "function_prepare_firewall_rules"
    end

    it 'error if no arguments' do
      lambda { @scope.function_prepare_firewall_rules([]) }.should \
        raise_error(ArgumentError,
          'prepare_firewall_rules(): wrong number of arguments (0; must be 6)')
    end

    it 'should require six arguments' do
      lambda { @scope.function_prepare_firewall_rules(
        ['a','b','c','d','e','f', 'g']) }.should \
        raise_error(ArgumentError,
          'prepare_firewall_rules(): wrong number of arguments (7; must be 6)')
    end

    it 'should require rule_basename to be a string' do
      lambda {
        @scope.function_prepare_firewall_rules([['0.0.0.0/0'],
          {'hash' => 'notastring'},nil,nil,nil,nil]) }.should \
          raise_error(ArgumentError,
            'prepare_firewall_rules(): rule_basename is not a string')
    end

    it 'should require source_nets to be an array of strings' do
      lambda {
        @scope.function_prepare_firewall_rules([['0.0.0.0/0', nil],
          '020 ssh',nil,nil,nil,nil]) }.should \
          raise_error(ArgumentError,
            'prepare_firewall_rules(): source_net is not an array of strings')
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
      expect(@scope.function_prepare_firewall_rules([['10.0.0.0/24',
        '10.0.1.0/24'],'020 ssh', 'accept', nil, '22', 'tcp'])).to eq result
    end

  end
end

