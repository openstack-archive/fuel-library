require 'spec_helper'

describe 'get_pair_of_jack_names' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  subject do
    function_name = Puppet::Parser::Functions.function(:get_pair_of_jack_names)
    scope.method(function_name)
  end

  context "t1" do

    it 'should exist' do
      subject == Puppet::Parser::Functions.function(:get_pair_of_jack_names)
    end

    it 'should throw an error on invalid types' do
      should run.with_params({:foo => :bar}).and_raise_error(Puppet::ParseError)
    end

    it 'should throw an error on invalid arguments number' do
      should run.with_params().and_raise_error(Puppet::ParseError)
      should run.with_params([1,2],[3,4]).and_raise_error(Puppet::ParseError)
    end

    it 'should return numbered interface names' do
      should run.with_params(['br-mgmt', 'br-ex']).and_return(["p_br-mgmt-0", "p_br-ex-1"])
    end

    it 'should cut interface names for long interfaces' do
      should run.with_params(['br-mmmmmmmmmmmmmmmmmmmmmmmmgmt', 'br-ex']).and_return(["p_br-mmmmmmmm-0", "p_br-ex-1"])
    end

  end
end