require 'spec_helper'

describe 'get_route_resource_name' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  subject do
    function_name = Puppet::Parser::Functions.function(:get_route_resource_name)
    scope.method(function_name)
  end

  context "get_route_resource_name" do

    it 'should exist' do
      subject == Puppet::Parser::Functions.function(:get_route_resource_name)
    end

    it 'should throw an error if called without args' do
      should run.with_params().and_raise_error(Puppet::ParseError)
    end

    it 'should throw an error if called with more two args' do
      should run.with_params('192.168.2.0/24', 10, 20).and_raise_error(Puppet::ParseError)
    end

    it do
      should run.with_params('192.168.2.0/24').and_return('192.168.2.0/24')
    end

    it do
      should run.with_params('192.168.2.0/24', 10).and_return('192.168.2.0/24,metric:10')
    end

    it do
      should run.with_params('192.168.2.0/24', 'xxx').and_return('192.168.2.0/24')
    end

  end
end
