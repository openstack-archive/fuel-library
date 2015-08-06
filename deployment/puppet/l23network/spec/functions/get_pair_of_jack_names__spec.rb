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

    it 'should return numbered interface names for pair of bridges' do
      should run.with_params(['br1', 'br2']).and_return(["p_39a440c1-0", "p_39a440c1-1"])
    end

    it 'should return numbered interface names for pair of bridges in reverse order' do
      should run.with_params(['br2', 'br1']).and_return(["p_39a440c1-0", "p_39a440c1-1"])
    end

    it 'should return numbered interface names for pair of bridges with long name' do
      should run.with_params(['br-mmmmmmmmmmmmmmmmmmmmmmmmgmt', 'br-ex']).and_return(["p_0c7224e9-0", "p_0c7224e9-1"])
    end

  end
end
# vim: set ts=2 sw=2 et