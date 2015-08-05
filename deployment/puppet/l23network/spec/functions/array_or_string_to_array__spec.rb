require 'spec_helper'

describe 'array_or_string_to_array' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it 'should exist' do
    expect(Puppet::Parser::Functions.function('array_or_string_to_array')).to eq('function_array_or_string_to_array')
  end

  it 'should throw an error on invalid types' do
    expect {
      scope.function_array_or_string_to_array([{:foo => :bar}])
    }.to(raise_error(Puppet::ParseError))
  end

  it 'should throw an error on invalid arguments number' do
    expect {
      scope.function_array_or_string_to_array([])
    }.to(raise_error(Puppet::ParseError))
    expect {
      scope.function_array_or_string_to_array([[1,2],[3,4]])
    }.to(raise_error(Puppet::ParseError))
  end

  it 'should return array if given array' do
    expect(scope.function_array_or_string_to_array([[1,2,3,4,5,6,7,8,9]])).to eq([1,2,3,4,5,6,7,8,9])
  end

  it 'should return array of strings if given string with separators' do
    expect(scope.function_array_or_string_to_array(['1,2,3,4,5:6,7 8,9'])).to eq(['1','2','3','4','5','6','7','8','9'])
  end
end