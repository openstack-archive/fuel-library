require 'spec_helper'

describe 'the structure function' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }


  it 'should exist' do
    expect(Puppet::Parser::Functions.function('structure')).to eq 'function_structure'
  end

  context 'single values' do

    it 'should be able to return a single value' do
      expect(scope.function_structure(['test'])).to eq 'test'
    end

    it 'should use the default value if data is a single value and path is present' do
      expect(scope.function_structure(['test', 'path', 'default'])).to eq 'default'
    end

    it 'should return default if there is no data' do
      expect(scope.function_structure([nil, nil, 'default'])).to eq 'default'
    end

    it 'should be able to use data structures as default values' do
      expect(scope.function_structure(['test', 'path', {'a' => 'a'}])).to eq({'a' => 'a'})
    end
  end

  context 'structure values' do
    it 'extracts a hash value' do
      data = {
        'a' => "1",
      }
      expect(scope.function_structure([data, 'a', '2'])).to eq '1'
    end

    it 'returns the default value if there is no hash value' do
      data = {
          'a' => "1",
      }
      expect(scope.function_structure([data, 'b', '2'])).to eq '2'
    end

    it 'should extract a deep hash value' do
      data = {
          'a' => {
              'b' => 'c'
          }
      }
      expect(scope.function_structure([data, 'a/b', 'default'])).to eq 'c'
    end

    it 'should return default value if path is not found' do
      data = {
          'a' => {
              'b' => 'c'
          }
      }
      expect(scope.function_structure([data, 'missing', 'default'])).to eq 'default'
    end

    it 'should return default if path is too long' do
      data = {
          'a' => {
              'b' => 'c'
          }
      }
      expect(scope.function_structure([data, 'a/b/c/d', 'default'])).to eq 'default'
    end

    it 'should support array index in the path' do
      data = {
          'a' => {
              'b' => ['b0', 'b1', 'b2', 'b3']
          }
      }
      expect(scope.function_structure([data, 'a/b/2', 'default'])).to eq 'b2'
    end

    it 'should return default if index is out of array length' do
      data = {
          'a' => {
              'b' => ['b0', 'b1', 'b2', 'b3']
          }
      }
      expect(scope.function_structure([data, 'a/b/5', 'default'])).to eq 'default'
    end

    it 'should be able to path though both array and hashes' do
      data = {
          'a' => {
              'b' => [
                  'b0',
                  'b1',
                  {
                      'x' => {
                          'y' => 'z'
                      }
                  },
                  'b3'
              ]
          }
      }
      expect(scope.function_structure([data, 'a/b/2/x/y', 'default'])).to eq 'z'
    end

    it 'should be able to return "true" value' do
      data = {
          'a' => false,
          'b' => true,
      }
      expect(scope.function_structure([data, 'b', 1])).to eq true
      expect(scope.function_structure([data, 'c', true])).to eq true
    end

    it 'should be able to return "false" value' do
      data = {
          'a' => false,
          'b' => true,
      }
      expect(scope.function_structure([data, 'a', 1])).to eq false
      expect(scope.function_structure([data, 'c', false])).to eq false
    end
  end
end
