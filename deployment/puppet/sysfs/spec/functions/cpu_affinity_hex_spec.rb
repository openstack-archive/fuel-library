require 'spec_helper'

describe 'the cpu_affinity_hex function' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it 'should exist' do
    expect(
        Puppet::Parser::Functions.function('cpu_affinity_hex')
    ).to eq('function_cpu_affinity_hex')
  end

  it 'should calculate HEX affinity value' do
    expect(
        scope.function_cpu_affinity_hex(%w(12))
    ).to eq 'fff'
    expect(
        scope.function_cpu_affinity_hex(%w(2))
    ).to eq '3'
  end

  it 'should calculate HEX affinity value for more 32 cpu' do
    expect(
        scope.function_cpu_affinity_hex(%w(32))
    ).to eq 'ffffffff'
    expect(
        scope.function_cpu_affinity_hex(%w(33))
    ).to eq 'ffffffff'
  end

  it 'should raise an error if there is less than 1 arguments' do
    expect {
      scope.function_cpu_affinity_hexs([])
    }.to raise_error
  end

  it 'should raise an error if value is not integer' do
    expect {
      scope.function_cpu_affinity_hex(%w(abc))
    }.to raise_error
  end

  it 'should raise an error if value is negative integer' do
    expect {
      scope.function_cpu_affinity_hex(%w(-1))
    }.to raise_error
  end

end
