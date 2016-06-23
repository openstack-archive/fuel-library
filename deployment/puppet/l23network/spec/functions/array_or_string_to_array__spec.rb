require 'spec_helper'

describe 'array_or_string_to_array' do

  it 'should throw an error on invalid types' do
    is_expected.to run.with_params({:foo => :bar}).and_raise_error(Puppet::ParseError)
  end

  it 'should throw an error on invalid arguments number' do
    is_expected.to run.with_params().and_raise_error(Puppet::ParseError)
    is_expected.to run.with_params([1,2],[3,4]).and_raise_error(Puppet::ParseError)
  end

  it 'should return array if given array' do
    is_expected.to run.with_params([1,2,3,4,5,6,7,8,9]).and_return([1,2,3,4,5,6,7,8,9])
  end

  it 'should return array of strings if given string with separators' do
    is_expected.to run.with_params('1,2,3,4,5:6,7 8,9').and_return(%w(1 2 3 4 5 6 7 8 9))
  end
end
