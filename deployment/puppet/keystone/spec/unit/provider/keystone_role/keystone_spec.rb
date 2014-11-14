require 'puppet'
require 'spec_helper'
require 'puppet/provider/keystone_role/keystone'

provider_class = Puppet::Type.type(:keystone_role).provider(:keystone)

describe provider_class do
  describe 'when query keystone objects' do
    it 'should not cache keystone objects in catalog' do
      provider_class.stubs(:build_role_hash).returns({ 'foo' => 'bar' })
      provider_class.role_hash.should == ({ 'foo' => 'bar' })
      provider_class.stubs(:build_role_hash).returns({ 'baz' => 'qux' })
      provider_class.role_hash.should == ({ 'baz' => 'qux' })
    end
  end
end
