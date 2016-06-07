require 'spec_helper'

describe 'generate_apt_pins' do

  it 'should exist' do
    is_expected.not_to be_nil
  end

  it 'should expect 1 argument' do
    is_expected.to run.with_params().and_raise_error(ArgumentError)
  end

  it 'should expect array as given argument' do
    is_expected.to run.with_params('foobar').and_raise_error(Puppet::ParseError)
  end
end
