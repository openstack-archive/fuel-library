# require 'puppet'
# require 'rspec'
# require 'rspec-puppet'
require 'spec_helper'
require 'puppetlabs_spec_helper/puppetlabs_spec/puppet_internals'

describe 'ethtool_convert_hash' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it 'should exist' do
    expect(Puppet::Parser::Functions.function('ethtool_convert_hash')).to eq 'function_ethtool_convert_hash'
  end

  it 'should throw an error on invalid arguments number #1' do
    expect {
      scope.function_ethtool_convert_hash([])
    }.to raise_error(Puppet::ParseError)
  end

  it 'should throw an error on invalid arguments number #2' do
    expect {
      scope.function_ethtool_convert_hash([{},{},{}])
    }.to raise_error(Puppet::ParseError)
  end

  it 'should throw an error on invalid argument type' do
    expect {
      scope.function_ethtool_convert_hash(['qweqwe'])
    }.to raise_error(Puppet::ParseError)
  end

  it 'should return hash with two sort of options' do
    rv = scope.function_ethtool_convert_hash([{
      :K => [
              'gso off',
              'gro off'
            ],
      :"set-channels" => [
               'rx 1',
               'tx 2',
               'other 3',
            ]
    }])
    expect(rv).to eq({
      '-K' => 'gso off  gro off',
      '--set-channels' => 'rx 1  tx 2  other 3'
    })
  end

  it 'should return hash with three sort of options with different case' do
    rv = scope.function_ethtool_convert_hash([{
      :s => [
              'xxx off',
              'yyy off'
            ],
      :K => [
              'gso off',
              'gro off'
            ],
      :"set-channels" => [
               'rx 1',
               'tx 2',
               'other 3',
            ]
    }])
    expect(rv).to eq({
      '-s' => 'xxx off  yyy off',
      '-K' => 'gso off  gro off',
      '--set-channels' => 'rx 1  tx 2  other 3'
    })

  end
end
