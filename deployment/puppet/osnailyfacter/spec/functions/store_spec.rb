require 'spec_helper'

describe 'the structure_Set function' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }


  it 'should exist' do
    expect(Puppet::Parser::Functions.function('store')).to eq 'function_store'
  end

  context 'structure values' do
    it 'should do nothing for non-structure values' do
      expect(scope.function_store(['test'])).to eq false
    end

    it 'should update a deep hash value' do
      data = {
          'a' => {
              'b' => 'c'
          }
      }
      expect(scope.function_store([data, 'a/b', 'c'])).to eq true
      expect(data['a']['b']).to eq 'c'
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
      expect(scope.function_store([data, 'a/b/1/d', '3'])).to eq true
      expect(data['a']['b'][1]['d']).to eq '3'
    end

  end
end
