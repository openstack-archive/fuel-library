require 'spec_helper'

describe 'array_part' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it 'should exist' do
    Puppet::Parser::Functions.function('array_part').should == 'function_array_part'
  end

  it 'should throw an error on invalid types' do
    lambda {
      scope.function_array_part([{:foo => :bar}])
    }.should(raise_error(Puppet::ParseError))
  end

  it 'should throw an error on invalid arguments number' do
    lambda {
      scope.function_array_part([[1,2,3,4,5,6,7,8],2])
    }.should(raise_error(Puppet::ParseError))
    lambda {
      scope.function_array_part([[1,2,3],1,2,3])
    }.should(raise_error(Puppet::ParseError))
    lambda {
      scope.function_array_part([])
    }.should(raise_error(Puppet::ParseError))
  end

  it 'should throw an error if 3d argument less of 2nd' do
    lambda {
      scope.function_array_part([[1,2,3,4,5],3,1])
    }.should(raise_error(Puppet::ParseError))
  end

  it 'should return NIL if empty array given' do
    scope.function_array_part([[],1,2]).should == nil
  end

  it 'should return NIL if 2nd parameter less than zero' do
    scope.function_array_part([[1,2,3,4,5],-1,2]).should == nil
  end

  it 'should return NIL if 2nd parameter more than array len' do
    scope.function_array_part([[1,2,3,4,5],100,2]).should == nil
  end

  it 'should return array of single element if 2nd  and 3d parameter are equal' do
    scope.function_array_part([[0,0,1,0,0],2,2]).should == [1]
  end

  it 'should work properly' do
    scope.function_array_part([[0,1,2,3,4,5,6,7,8,9],2,5]).should == [2,3,4,5]
  end

  it 'should return from given index to end' do
    scope.function_array_part([[0,1,2,3,4,5,6,7,8,9],2,0]).should == [2,3,4,5,6,7,8,9]
  end

  it 'should return undef if requested range out of given array' do
    scope.function_array_part([[0,1],2,0]).should == nil
  end

end