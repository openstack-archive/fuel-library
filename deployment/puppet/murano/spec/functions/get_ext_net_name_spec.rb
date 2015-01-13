require 'spec_helper'

describe 'get_ext_net_name' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it 'should exist' do
    Puppet::Parser::Functions.function('get_ext_net_name').should == 'function_get_ext_net_name'
  end

  it 'should return the network name that has router_ext enabled' do
    expect(scope.function_get_ext_net_name(
      [
        {
          "net04" =>
          {
            "L2" =>
            {
              "router_ext"   => false,
            }
          },
          "net04_ext" =>
          {
            "L2" =>
            {
              "router_ext"   => true,
            }
          }
        }
      ]
    )).to eq 'net04_ext'
  end

  it 'should return nil if router_ext is not enabled' do
    expect(scope.function_get_ext_net_name(
      [
        {
          "net04" =>
          {
            "L2" =>
            {
              "router_ext"   => false,
            }
          },
          "net04_ext" =>
          {
            "L2" =>
            {
              "router_ext"   => false,
            }
          }
        }
      ],
    )).to be_nil
  end

  it 'should return nil if there is no router_ext' do
    expect(scope.function_get_ext_net_name(
      [
        {
          "net04" =>
          {
            "L2" =>
            {
            }
          },
          "net04_ext" =>
          {
            "L2" =>
            {
            }
          }
        }
      ]
    )).to be_nil
  end

  it 'should return nil with empty network data' do
    expect(scope.function_get_ext_net_name(
      [
        {}
      ]
    )).to be_nil
  end

end
