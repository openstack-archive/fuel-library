require 'spec_helper'

describe 'get_patch_name' do

  it 'should exist' do
    is_expected.not_to be_nil
  end

  context "t1" do

    it 'should throw an error on invalid types' do
      is_expected.to run.with_params({:foo => :bar}).and_raise_error(Puppet::ParseError)
    end

    it 'should throw an error on invalid arguments number' do
      is_expected.to run.with_params().and_raise_error(Puppet::ParseError)
      is_expected.to run.with_params([1,2],[3,4]).and_raise_error(Puppet::ParseError)
    end

    it 'should return numbered interface names' do
      is_expected.to run.with_params(['br-mgmt', 'br-ex']).and_return("patch__br-ex--br-mgmt")
    end

    #todo(sv): should be refactoded reo returns more shot name
    # it 'should cut interface names for long interfaces' do
    #   is_expected.to run.with_params(['br-mmmmmmmmmmmmmmmmmmmmmmmmgmt', 'br-ex']).and_return(["p_br-mmmmmmmm-0", "p_br-ex-1"])
    # end

  end
end
