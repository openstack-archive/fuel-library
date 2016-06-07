require 'spec_helper'

describe 'nic_whitelist_to_mappings' do

  let(:nic_whitelist) do
   [{"devname"=>"eth1", "physical_network"=>"physnet2"}]
  end

  let(:physical_device_mappings) do
   ["physnet2:eth1"]
  end

  before(:each) do
    puppet_debug_override
  end

  it 'should exist' do
    is_expected.not_to be_nil
  end

  it 'should fail if more then one argument given' do
    is_expected.to run.with_params(nic_whitelist, 'eee').and_raise_error(Puppet::ParseError)
  end

  it 'should return without arguments' do
    is_expected.to run.with_params().and_return(nil)
  end

  it 'should convert nic whitelist to device mappings' do
    is_expected.to run.with_params(nic_whitelist).and_return(physical_device_mappings)
  end

end
