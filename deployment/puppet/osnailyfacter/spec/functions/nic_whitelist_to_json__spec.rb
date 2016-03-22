require 'spec_helper'

describe 'nic_whitelist_to_json' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }
  let(:nic_whitelist) do
   [{"devname"=>"eth1", "physical_network"=>"physnet2"}]
  end
  let(:nic_whitelist_json) do
   "[{\"devname\":\"eth1\",\"physical_network\":\"physnet2\"}]"
  end

  before(:each) do
    puppet_debug_override()
  end

  it 'should exist' do
    expect(Puppet::Parser::Functions.function('nic_whitelist_to_json')).to eq('function_nic_whitelist_to_json')
  end

  it 'should fail if more then one argument given' do
    expect{scope.function_nic_whitelist_to_json([nic_whitelist, 'eee'])}.to raise_error(Puppet::ParseError, /one argument is allowed/)
  end

  it 'should return without arguments' do
    expect(scope.function_nic_whitelist_to_json([])).to eq(nil)
  end

  it 'should convert nic whitelist to json' do
    expect(scope.function_nic_whitelist_to_json([nic_whitelist])).to eq(nic_whitelist_json)
  end

end
