require 'spec_helper'
require 'rspec-puppet-utils'

describe 'get_node_key_name' do
  it 'should exist' do
    is_expected.not_to be_nil
  end

  it 'should be able to calculate node key name' do
    Puppet::Parser::Functions.autoloader.load :hiera
    MockFunction.new('hiera') { |f|
      f.stubs(:call).with(%w(uid)).returns('121')
    }
    is_expected.to run.with_params().and_return('node-121')
  end

  it 'should raise error if UID not given' do
    Puppet::Parser::Functions.autoloader.load :hiera
    MockFunction.new('hiera') { |f|
      f.stubs(:call).with(%w(uid)).returns(nil)
    }
    is_expected.to run.with_params().and_raise_error(Puppet::ParseError)
  end

end
