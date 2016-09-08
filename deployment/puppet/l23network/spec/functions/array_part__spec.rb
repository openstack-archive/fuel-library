require 'spec_helper'

describe 'array_part' do

  it 'should exist' do
    is_expected.not_to be_nil
  end

  it 'should throw an error on invalid types' do
    is_expected.to run.with_params({:foo => :bar}).and_raise_error(Puppet::ParseError)
  end

  it 'should throw an error on invalid arguments number' do
    is_expected.to run.with_params([1,2,3,4,5,6,7,8],2).and_raise_error(Puppet::ParseError)
    is_expected.to run.with_params([[1,2,3],1,2,3]).and_raise_error(Puppet::ParseError)
    is_expected.to run.with_params([]).and_raise_error(Puppet::ParseError)
  end

  it 'should throw an error if 3d argument less of 2nd' do
    is_expected.to run.with_params([1,2,3,4,5],3,1).and_raise_error(Puppet::ParseError)
  end

  it 'should return NIL if empty array given' do
    is_expected.to run.with_params([],1,2).and_return(nil)
  end

  it 'should return NIL if 2nd parameter less than zero' do
    is_expected.to run.with_params([1,2,3,4,5],-1,2).and_return(nil)
  end

  it 'should return NIL if 2nd parameter more than array len' do
    is_expected.to run.with_params([1,2,3,4,5],100,2).and_return(nil)
  end

  it 'should return array of single element if 2nd  and 3d parameter are equal' do
    is_expected.to run.with_params([0,0,1,0,0],2,2).and_return([1])
  end

  it 'should work properly' do
    is_expected.to run.with_params([0,1,2,3,4,5,6,7,8,9],2,5).and_return([2,3,4,5])
  end

  it 'should return from given index to end' do
    is_expected.to run.with_params([0,1,2,3,4,5,6,7,8,9],2,0).and_return([2,3,4,5,6,7,8,9])
  end

  it 'should return undef if requested range out of given array' do
    is_expected.to run.with_params([0,1],2,0).and_return(nil)
  end

end
