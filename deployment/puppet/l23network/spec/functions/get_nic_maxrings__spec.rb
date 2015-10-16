require 'spec_helper'
require 'puppetx/l23_utils'

describe 'get_nic_maxrings' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it 'should exist' do
    expect(Puppet::Parser::Functions.function('get_nic_maxrings')).to eq 'function_get_nic_maxrings'
  end

  it 'should throw an error on invalid arguments number' do
    expect{ scope.function_get_nic_maxrings([]) }.to raise_error(Puppet::ParseError)
  end

  it 'should return hash with rings rx/tx values' do
    preset_rxtx = { 'RX' => '2048', 'TX' => '2048' }
    rings = { 'rings' => preset_rxtx }

    L23network.stubs(:get_ethtool_rings).with('eth0').returns(preset_rxtx)
    expect(scope.function_get_nic_maxrings(['eth0'])).to eq(rings)
  end

end
# vim: set ts=2 sw=2 et
