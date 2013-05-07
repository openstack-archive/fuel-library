require 'spec_helper'

describe 'merge_arrays' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it 'should exist' do
    Puppet::Parser::Functions.function('merge_arrays').should == 'function_merge_arrays'
  end

  it 'should throw an error on invalid types' do
    lambda {
      scope.function_merge_arrays([{:foo => :bar}])
    }.should(raise_error(Puppet::ParseError))
  end

  it 'should throw an error on invalid arguments number' do
    lambda {
      scope.function_merge_arrays([])
    }.should(raise_error(Puppet::ParseError))
  end

  it 'should return array' do
    scope.function_merge_arrays([[1,2,3],[4,5,6],[7,8,9]]).should == [1,2,3,4,5,6,7,8,9]
  end
end