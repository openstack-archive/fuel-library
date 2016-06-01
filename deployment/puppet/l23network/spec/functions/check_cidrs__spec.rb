require 'spec_helper'

describe 'check_cidrs' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it 'should exist' do
    expect(Puppet::Parser::Functions.function('check_cidrs')).to eq 'function_check_cidrs'
  end

  it 'should throw an error on invalid arguments number' do
    expect do
      scope.function_check_cidrs(['a','b'])
    end.to raise_error(Puppet::ParseError)
  end

  it 'should throw an error on invalid types' do
    expect do
      scope.function_check_cidrs([{:foo => :bar}])
    end.to raise_error(Puppet::ParseError)
  end

  it 'should throw an error on invalid CIDRs' do
    invalid_cidrs = ['192.168.33.66', '192.256.33.66/23', '192.168.33.66/33', '192.168.33.66/333', 'jhgjhgghggh']
    expect do
      scope.function_check_cidrs([invalid_cidrs])
    end.to raise_error(Puppet::ParseError)
  end

end
