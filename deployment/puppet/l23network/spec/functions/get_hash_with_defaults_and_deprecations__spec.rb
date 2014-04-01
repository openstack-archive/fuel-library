# require 'puppet'
# require 'rspec'
# require 'rspec-puppet'
require 'spec_helper'
require 'puppetlabs_spec_helper/puppetlabs_spec/puppet_internals'

describe 'get_hash_with_defaults_and_deprecations' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it 'should exist' do
    expect(Puppet::Parser::Functions.function('get_hash_with_defaults_and_deprecations')).to eq 'function_get_hash_with_defaults_and_deprecations'
  end

  it 'should throw an error on invalid arguments number #1' do
    expect {
      scope.function_get_hash_with_defaults_and_deprecations([])
    }.to raise_error(Puppet::ParseError)
  end

  it 'should throw an error on invalid arguments number #2' do
    expect {
      scope.function_get_hash_with_defaults_and_deprecations([{},{}])
    }.to raise_error(Puppet::ParseError)
  end

  it 'should throw an error on invalid arguments number #3' do
    expect {
      scope.function_get_hash_with_defaults_and_deprecations([{},{},{},{}])
    }.to raise_error(Puppet::ParseError)
  end

  it 'should throw an error on invalid argument type' do
    expect {
      scope.function_get_hash_with_defaults_and_deprecations(['qweqwe'])
    }.to raise_error(Puppet::ParseError)
  end

  it 'should return hash with sum of two hashes' do
    rv = scope.function_get_hash_with_defaults_and_deprecations([{
      'aaa' => 1,
      'bbb' => 2,
    }, {
      'ccc' => 3,
      'ddd' => 4,
    }, {}])
    expect(rv).to eq({
      'aaa' => 1,
      'bbb' => 2,
      'ccc' => 3,
      'ddd' => 4,
    })
  end

  it 'should return hash with sum of two hashes, add defaults if need' do
    rv = scope.function_get_hash_with_defaults_and_deprecations([{
      'aaa' => 1,
      'bbb' => 2,
    }, {
      'bbb' => -1,
      'ccc' => 3,
      'ddd' => 4,
    }, {}])
    expect(rv).to eq({
      'aaa' => 1,
      'bbb' => 2,
      'ccc' => 3,
      'ddd' => 4,
    })
  end

  it 'should return hash with sum of three hashes' do
    rv = scope.function_get_hash_with_defaults_and_deprecations([{
      'aaa' => 1,
      'bbb' => 2,
    }, {
      'bbb' => -1,
      'ccc' => 3,
      'ddd' => 4,
    }, {
      'eee' => 5,
    }])
    expect(rv).to eq({
      'aaa' => 1,
      'bbb' => 2,
      'ccc' => 3,
      'ddd' => 4,
      'eee' => 5,
    })
  end


  # it 'should return hash with three sort of options with different case' do
  #   rv = scope.function_get_hash_with_defaults_and_deprecations([{
  #     :s => [
  #             'xxx off',
  #             'yyy off'
  #           ],
  #     :K => [
  #             'gso off',
  #             'gro off'
  #           ],
  #     :"set-channels" => [
  #              'rx 1',
  #              'tx 2',
  #              'other 3',
  #           ]
  #   }])
  #   expect(rv).to eq({
  #     '-s' => 'xxx off  yyy off',
  #     '-K' => 'gso off  gro off',
  #     '--set-channels' => 'rx 1  tx 2  other 3'
  #   })

  # end
end
