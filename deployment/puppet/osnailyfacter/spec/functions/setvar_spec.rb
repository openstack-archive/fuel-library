require 'spec_helper'

describe 'the setvar function' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }


  it 'should exist' do
    expect(Puppet::Parser::Functions.function('setvar')).to eq 'function_setvar'
  end

  before(:each) do
    scope.function_setvar ['test', 'test']
  end

  it 'sets the initial test value' do
    expect(scope.lookupvar 'test').to eq 'test'
  end

  it 'can rewrite a variable value' do
    scope.function_setvar ['test', '2']
    expect(scope.lookupvar 'test').to eq '2'
  end

  it 'can set a boolean values' do
    scope.function_setvar ['test', true]
    expect(scope.lookupvar 'test').to eq true
  end

  it 'can set an Array values' do
    scope.function_setvar ['test', ['1','2']]
    expect(scope.lookupvar 'test').to eq ['1','2']
  end

  it 'can set a Hash values' do
    scope.function_setvar ['test', {'1' => '2'}]
    expect(scope.lookupvar 'test').to eq ({'1' => '2'})
  end

  it 'can set an Undef value' do
    scope.function_setvar ['test', nil]
    expect(scope.lookupvar 'test').to eq nil
  end

  it 'can save non-string values a s string' do
    scope.function_setvar ['test', 1]
    expect(scope.lookupvar 'test').to eq '1'
    scope.function_setvar ['test', :a]
    expect(scope.lookupvar 'test').to eq 'a'
  end
end
