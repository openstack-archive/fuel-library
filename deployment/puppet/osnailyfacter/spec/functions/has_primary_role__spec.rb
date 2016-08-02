require 'spec_helper'

describe 'has_primary_role' do

  it 'should exist' do
    is_expected.not_to be_nil
  end

  it 'should throw an error on invalid arguments number' do
    is_expected.to run.with_params(1, 2).and_raise_error(ArgumentError)
  end

  it 'should raise an error if invalid argument type is specified' do
    is_expected.to run.with_params('foo').and_raise_error(Puppet::ParseError)
  end

  it 'should return true if primary role is present' do
    is_expected.to run.with_params(['database', 'primary-controller']).and_return(true)
  end

  it 'should return false if primary role is not present' do
    is_expected.to run.with_params(['controller', 'rabbitmq']).and_return(false)
  end

end
