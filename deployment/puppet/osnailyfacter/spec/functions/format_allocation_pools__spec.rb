require 'puppet'
require 'spec_helper'

describe 'function for formating allocation pools for neutron subnet resource' do

  def setup_scope
    @compiler = Puppet::Parser::Compiler.new(Puppet::Node.new("floppy", :environment => 'production'))
    @scope = Puppet::Parser::Scope.new(@compiler)
    @topscope = @topscope
    @scope.parent = @topscope
    Puppet::Parser::Functions.function(:format_allocation_pools)
  end

  describe 'basic tests' do

    before :each do
      setup_scope
      puppet_debug_override
    end

    it "should exist" do
      Puppet::Parser::Functions.function(:format_allocation_pools).should == "function_format_allocation_pools"
    end

    it 'error if no arguments' do
      lambda { @scope.function_format_allocation_pools([]) }.should raise_error(ArgumentError, 'format_allocation_pools(): wrong number of arguments (0; must be 1 or 2)')
    end

    it 'should fail with wrong number of arguments' do
      lambda { @scope.function_format_allocation_pools(['foo', 'wee', 'bla']) }.should raise_error(ArgumentError, 'format_allocation_pools(): wrong number of arguments (3; must be 1 or 2)')
    end

    it 'should require floating ranges is Array' do
      lambda { @scope.function_format_allocation_pools([{:fff => true}, 'cidr']) }.should raise_error(ArgumentError, 'format_allocation_pools(): floating_ranges is not array!')
    end

    it 'should require floating cidr is String' do
      lambda { @scope.function_format_allocation_pools([['foo', 'wee'], ['cidr']]) }.should raise_error(ArgumentError, 'format_allocation_pools(): floating_cidr is not string!')
    end

    it 'should be able to format allocation pool string with optional CIDR parameter' do
      expect(@scope.function_format_allocation_pools([["10.109.1.151:10.109.1.254", "10.109.1.130:10.109.1.150"], "10.109.1.0/24"])).to eq(["start=10.109.1.151,end=10.109.1.254", "start=10.109.1.130,end=10.109.1.150"])
    end

    it 'should be able to format allocation pool string without optional CIDR parameter' do
      expect(@scope.function_format_allocation_pools([["10.109.1.151:10.109.1.254", "10.109.1.130:10.109.1.150"]])).to eq(["start=10.109.1.151,end=10.109.1.254", "start=10.109.1.130,end=10.109.1.150"])
    end

    it 'should be able to format allocation pool string for old structure' do
      expect(@scope.function_format_allocation_pools(["10.109.1.133:10.109.1.169", "10.109.1.0/24"])).to eq(["start=10.109.1.133,end=10.109.1.169"])
    end

    it 'should be able to format allocation pool string and skip range that does not match CIDR' do
      expect(@scope.function_format_allocation_pools([["10.109.1.151:10.109.1.254", "10.110.1.130:10.110.1.150"], "10.109.1.0/24"])).to eq(["start=10.109.1.151,end=10.109.1.254"])
    end
  end
end
