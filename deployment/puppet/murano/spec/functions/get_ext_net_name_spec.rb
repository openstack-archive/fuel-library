require 'spec_helper'

describe 'get_ext_net_name' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it 'should exist' do
    Puppet::Parser::Functions.function('get_ext_net_name').should == 'function_get_ext_net_name'
  end

  it 'should return network specified in net04_ext' do
    scope.function_get_ext_net_name(
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
        },
        'net99_ext'
      ]
    ).should eql 'net04_ext'
  end

  it 'should return default_net' do
    scope.function_get_ext_net_name(
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
        },
        'net99_ext'
      ],
    ).should eql 'net99_ext'
  end

  it 'should return default_net' do
    scope.function_get_ext_net_name(
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
        },
        'net99_ext'
      ]
    ).should eql 'net99_ext'
  end

  it 'should return default_net' do
    scope.function_get_ext_net_name(
      [
        {},
        'net99_ext'
      ]
    ).should eql 'net99_ext'
  end

end
