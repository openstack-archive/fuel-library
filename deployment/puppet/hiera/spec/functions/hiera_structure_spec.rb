require 'spec_helper'

describe 'the hiera_structure function' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }


  it 'should exist' do
    expect(Puppet::Parser::Functions.function('hiera_structure')).to eq 'function_hiera_structure'
  end

  it 'should raise error if there is less than 1 arguments' do
    expect {
      scope.function_hiera_structure([])
    }.to raise_error
  end

  context 'single values' do
    it 'should be able to extract a single value' do
      HieraPuppet.expects(:lookup).returns('value').with { |*args| args.first == 'test' }
      expect(scope.function_hiera_structure(['test'])).to eq 'value'
    end

    it 'should use the default value if key is not found' do
      HieraPuppet.expects(:lookup).returns(nil).with { |*args| args.first == 'missing' }
      expect(scope.function_hiera_structure(['missing', 'default'])).to eq 'default'
    end

    it 'should be able to use data structures as default values' do
      HieraPuppet.expects(:lookup).returns(nil).with { |*args| args.first == 'missing' }
      expect(scope.function_hiera_structure(['missing', {}])).to eq({})
    end
  end

  context 'structure values' do
    it 'should extract a deep hash value' do
      HieraPuppet.expects(:lookup).returns(
          {
              'a' => {
                  'b' => 'c'
              }
          }
      ).with { |*args| args.first == 'test' }
      expect(scope.function_hiera_structure(['test/a/b', 'default'])).to eq 'c'
    end

    it 'should return default value if path is not found' do
      HieraPuppet.expects(:lookup).returns(
          {
              'a' => {
                  'b' => 'c'
              }
          }
      ).with { |*args| args.first == 'test' }
      expect(scope.function_hiera_structure(['test/missing/b', 'default'])).to eq 'default'
    end

    it 'should return default if path is too long' do
      HieraPuppet.expects(:lookup).returns(
          {
              'a' => {
                  'b' => 'c'
              }
          }
      ).with { |*args| args.first == 'test' }
      expect(scope.function_hiera_structure(['test/a/b/c', 'default'])).to eq 'default'
    end

    it 'should support array index in the path' do
      HieraPuppet.expects(:lookup).returns(
          {
              'a' => {
                  'b' => ['b0', 'b1', 'b2', 'b3']
              }
          }
      ).with { |*args| args.first == 'test' }
      expect(scope.function_hiera_structure(['test/a/b/2', 'default'])).to eq 'b2'
    end

    it 'should return default if index is out of array length' do
      HieraPuppet.expects(:lookup).returns(
          {
              'a' => {
                  'b' => ['b0', 'b1', 'b2', 'b3']
              }
          }
      ).with { |*args| args.first == 'test' }
      expect(scope.function_hiera_structure(['test/a/b/5', 'default'])).to eq 'default'
    end

    it 'should be able to path though both array and hashes' do
      HieraPuppet.expects(:lookup).returns(
          {
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
      ).with { |*args| args.first == 'test' }
      expect(scope.function_hiera_structure(['test/a/b/2/x/y', 'default'])).to eq 'z'
    end
  end
end
