require 'spec_helper'

describe 'cpu_affinity_hex' do
  it 'should exist' do
    is_expected.not_to be_nil
  end

  it 'should calculate HEX affinity value' do
    is_expected.to run.with_params(12).and_return('fff')
    is_expected.to run.with_params(2).and_return('3')
  end

  it 'should calculate HEX affinity value for more 32 cpu' do
    is_expected.to run.with_params(32).and_return('ffffffff')
    is_expected.to run.with_params(33).and_return('ffffffff')
  end

  it 'should raise an error if there is less than 1 arguments' do
    is_expected.to run.with_params().and_raise_error(Puppet::Error)
  end

  it 'should raise an error if value is not integer' do
    is_expected.to run.with_params('abc').and_raise_error(Puppet::Error)
  end

  it 'should raise an error if value is negative integer' do
    is_expected.to run.with_params(-1).and_raise_error(Puppet::Error)
  end

end
