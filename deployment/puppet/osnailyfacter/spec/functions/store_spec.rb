require 'spec_helper'

describe 'the store function' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }


  it 'should exist' do
    expect(Puppet::Parser::Functions.function('store')).to eq 'function_store'
  end

  it 'should do nothing for non-structure values and raise error' do
    data = 'test'
    expect {
      scope.function_store [data, 'a/b', 'c']
    }.to raise_error
    expect(data).to eq 'test'
  end

  it 'should update a deep hash value' do
    data = {
        'a' => {
            'b' => 'c'
        }
    }
    scope.function_store [data, 'a/b', 'd']
    expect(data['a']['b']).to eq 'd'
  end

  it 'should support array index in the path' do
    data = {
        'a' => {
            'b' => [
                { 'c' => '1' },
                { 'd' => '2' },
            ]
        }
    }
    scope.function_store [data, 'a/b/1/d', '3']
    expect(data['a']['b'][1]['d']).to eq '3'
  end

  it 'should raise error if path is not correct for a hash and value was not set' do
    data = {
        'a' => {
            'b' => [
                { 'c' => '1' },
                { 'd' => '2' },
            ]
        }
    }
    expect {
      scope.function_store [data, 'a/x/1/d', '3']
    }.to raise_error
  end

  it 'should raise error if path is not correct for an array and value was not set' do
    data = {
        'a' => {
            'b' => [
                { 'c' => '1' },
                { 'd' => '2' },
            ]
        }
    }
    expect {
      scope.function_store [data, 'a/b/2/d', '3']
    }.to raise_error
  end

  it 'should be able to use a custom path separator' do
    data = {
        'a' => {
            'b' => 'c'
        }
    }
    scope.function_store [data, 'a::b', 'd', '::']
    expect(data['a']['b']).to eq 'd'
  end

end
