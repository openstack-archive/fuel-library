require 'spec_helper'

describe 'nic_whitelist_to_json' do

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
    is_expected.not_to be_nil
  end

  it 'should fail if more then one argument given' do
    is_expected.to run.with_params(nic_whitelist, 'eee').and_raise_error(Puppet::ParseError)
  end

  it 'should return without arguments' do
    is_expected.to run.with_params().and_return(nil)
  end

  it 'should convert nic whitelist to json' do
    is_expected.to run.with_params(nic_whitelist).and_return(nic_whitelist_json)
  end

end
