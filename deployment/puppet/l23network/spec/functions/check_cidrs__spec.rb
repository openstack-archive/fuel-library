require 'spec_helper'

describe 'check_cidrs' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it 'should exist' do
    Puppet::Parser::Functions.function('check_cidrs').should == 'function_check_cidrs'
  end

  it 'should throw an error on invalid arguments number' do
    lambda {
      scope.function_check_cidrs(['a','b'])
    }.should(raise_error(Puppet::ParseError))
  end

  it 'should throw an error on invalid types' do
    lambda {
      scope.function_check_cidrs([{:foo => :bar}])
    }.should(raise_error(Puppet::ParseError))
  end

  it 'should throw an error on invalid CIDRs' do
    invalid_cidrs = ['192.168.33.66', '192.256.33.66/23', '192.168.33.66/33', '192.168.33.66/333', 'jhgjhgghggh']
    lambda {
      scope.function_check_cidrs([invalid_cidrs])
    }.should(raise_error(Puppet::ParseError))
  end

end