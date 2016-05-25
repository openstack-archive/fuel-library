require 'spec_helper'

describe 'array_part' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it 'should exist' do
    expect(Puppet::Parser::Functions.function('array_part')).to eq 'function_array_part'
  end

  it 'should throw an error on invalid types' do
    expect do
      scope.function_array_part([{:foo => :bar}])
    end.to raise_error(Puppet::ParseError)
  end

  it 'should throw an error on invalid arguments number' do
    expect do
      scope.function_array_part([[1,2,3,4,5,6,7,8],2])
    end.to raise_error(Puppet::ParseError)
    expect do
      scope.function_array_part([[1,2,3],1,2,3])
    end.to raise_error(Puppet::ParseError)
    expect do
      scope.function_array_part([])
    end.to raise_error(Puppet::ParseError)
  end

  it 'should throw an error if 3d argument less of 2nd' do
    expect do
      scope.function_array_part([[1,2,3,4,5],3,1])
    end.to raise_error(Puppet::ParseError)
  end

  it 'should return NIL if empty array given' do
    expect(scope.function_array_part([[],1,2])).to eq nil
  end

  it 'should return NIL if 2nd parameter less than zero' do
    expect(scope.function_array_part([[1,2,3,4,5],-1,2])).to eq nil
  end

  it 'should return NIL if 2nd parameter more than array len' do
    expect(scope.function_array_part([[1,2,3,4,5],100,2])).to eq nil
  end

  it 'should return array of single element if 2nd  and 3d parameter are equal' do
    expect(scope.function_array_part([[0,0,1,0,0],2,2])).to eq([1])
  end

  it 'should work properly' do
    expect(scope.function_array_part([[0,1,2,3,4,5,6,7,8,9],2,5])).to eq([2,3,4,5])
  end

  it 'should return from given index to end' do
    expect(scope.function_array_part([[0,1,2,3,4,5,6,7,8,9],2,0])).to eq([2,3,4,5,6,7,8,9])
  end

  it 'should return undef if requested range out of given array' do
    expect(scope.function_array_part([[0,1],2,0])).to eq nil
  end

end
