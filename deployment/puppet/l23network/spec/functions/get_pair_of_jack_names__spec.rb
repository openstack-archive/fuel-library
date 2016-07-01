require 'spec_helper'

# NOTE: In this test 'p_39a440c1-N' is a patchcord name for
# ['br1', 'br2'] bridges. Central part of name calculated as
# CRC32 of patchcord resource name and depends ONLY of bridge
# names, that connected by patchcord.

describe 'get_pair_of_jack_names' do

  it 'should exist' do
    is_expected.not_to be_nil
  end

  context "t1" do

    it 'should throw an error on invalid types' do
      is_expected.to run.with_params({:foo => :bar}).and_raise_error(Puppet::ParseError)
    end

    it 'should throw an error on invalid arguments number' do
      is_expected.to run.with_params().and_raise_error(Puppet::ParseError)
      is_expected.to run.with_params([1, 2], [3, 4]).and_raise_error(Puppet::ParseError)
    end

    it 'should return numbered interface names for pair of bridges' do
      is_expected.to run.with_params(['br1', 'br2']).and_return(["p_39a440c1-0", "p_39a440c1-1"])
    end

    it 'should return numbered interface names for pair of bridges in reverse order' do
      is_expected.to run.with_params(['br2', 'br1']).and_return(["p_39a440c1-0", "p_39a440c1-1"])
    end

    it 'should return numbered interface names for pair of bridges with long name' do
      is_expected.to run.with_params(['br-mmmmmmmmmmmmmmmmmmmmmmmmgmt', 'br-ex']).and_return(["p_0c7224e9-0", "p_0c7224e9-1"])
    end

  end
end
