require 'spec_helper'

describe 'check_cidrs' do

  it 'should throw an error on invalid arguments number' do
    is_expected.to run.with_params('a','b').and_raise_error(Puppet::ParseError)
  end

  it 'should throw an error on invalid types' do
    is_expected.to run.with_params({:foo => :bar}).and_raise_error(Puppet::ParseError)
  end

  it 'should throw an error on invalid CIDRs' do
    invalid_cidrs = ['192.168.33.66', '192.256.33.66/23', '192.168.33.66/33', '192.168.33.66/333', 'jhgjhgghggh']
    is_expected.to run.with_params(invalid_cidrs).and_raise_error(Puppet::ParseError)
  end

end
