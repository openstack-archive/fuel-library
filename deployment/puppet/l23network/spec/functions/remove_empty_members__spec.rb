require 'spec_helper'
require 'yaml'

describe 'remove empty interfaces and endpoints' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  before :each do
    puppet_debug_override
  end

  it 'should exist' do
    Puppet::Parser::Functions.function('remove_empty_members').should == 'function_remove_empty_members'
  end

  it 'should has ability to remove empty keys from config hashes' do
    expect(scope.function_remove_empty_members([{
      :endpoints => {
        :"br-fw-admin"=>
          {"IP"=>["10.88.0.7/24"],
           "gateway"=>"",
           "vendor_specific"=>{"provider_gateway"=>"10.88.0.2"}},
         "br-mesh"=>""
      },
      :interfaces=> {
          "enp0s3"=>{"vendor_specific"=>{"bus_info"=>"0000:00:03.0", "driver"=>"e1000"}},
          "enp0s4"=> ""
      },
      :provider=>"lnx"
    }])).to eq({
      :endpoints => {
        :"br-fw-admin"=>
          {"IP"=>["10.88.0.7/24"],
           "gateway"=>"",
           "vendor_specific"=>{"provider_gateway"=>"10.88.0.2"}},
      },
      :interfaces=> {
          "enp0s3"=>{"vendor_specific"=>{"bus_info"=>"0000:00:03.0", "driver"=>"e1000"}},
      },
      :provider=>"lnx",
    })
  end

end
# vim: set ts=2 sw=2 et :