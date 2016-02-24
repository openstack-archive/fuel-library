require 'spec_helper'

describe 'the get_node_key_name function' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it 'should exist' do
    expect(
        Puppet::Parser::Functions.function('get_node_key_name')
    ).to eq('function_get_node_key_name')
  end

  it 'should be able to calculate node key name' do
    scope.stubs(:function_hiera).with(['uid']).returns('1')
    scope.stubs(:function_hiera).with(['network_metadata']).returns({"nodes"=>
               {"controller-21853"=>{"swift_zone"=>"2", "uid"=>"2", "fqdn"=>"controller-21853.test.domain.local"},
                "controller-9864"=>{"swift_zone"=>"1", "uid"=>"1", "fqdn"=>"controller-9864.test.domain.local"}
               }})
    expect(scope.function_get_node_key_name []).to eq 'controller-9864'
  end

  it 'should raise error if UID not gived' do
    scope.stubs(:function_hiera).with(['uid']).returns(nil)
    scope.stubs(:function_hiera).with(['network_metadata']).returns({})
    expect{scope.function_get_node_key_name []}.to raise_error(Puppet::ParseError)
  end

end
