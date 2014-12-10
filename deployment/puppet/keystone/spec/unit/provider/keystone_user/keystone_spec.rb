require 'puppet'
require 'spec_helper'
require 'puppet/provider/keystone_user/keystone'

provider_class = Puppet::Type.type(:keystone_user).provider(:keystone)

describe provider_class do

  describe 'when updating a user' do
    let :resource do
      Puppet::Type::Keystone_user.new(
        {
          :name         => 'foo',
          :ensure       => 'present',
          :enabled      => 'True',
          :tenant       => 'foo2',
          :email        => 'foo@foo.com',
          :password     => 'passwd'
        }
      )
    end

    let :provider do
      provider_class.new(resource)
    end

    before :each do
      provider_class.expects(:build_user_hash).at_least(1).returns(
        'foo' => {:id   => 'id', :name => 'foo', :tenant => 'foo2', :password => 'passwd'}
      )
    end

    after :each do
      # reset global state
      provider_class.prefetch(nil)
    end

    it 'should call user-password-update to change password' do
      provider.expects(:auth_keystone).with('user-password-update', '--pass', 'newpassword', 'id')
      provider.password=('newpassword')
    end
  end

  describe 'when query keystone objects' do
    it 'should not cache keystone objects in catalog' do
      provider_class.stubs(:build_user_hash).returns({ 'foo' => 'bar' })
      provider_class.user_hash.should == ({ 'foo' => 'bar' })
      provider_class.stubs(:build_user_hash).returns({ 'baz' => 'qux' })
      provider_class.user_hash.should == ({ 'baz' => 'qux' })
    end
  end

  describe 'when updating a user with unmanaged password' do
    let :resource do
      Puppet::Type::Keystone_user.new(
        {
          :name            => 'foo',
          :ensure          => 'present',
          :enabled         => 'True',
          :tenant          => 'foo2',
          :email           => 'foo@foo.com',
          :password        => 'passwd',
          :manage_password => 'False',
        }
      )
    end

    let :provider do
      provider_class.new(resource)
    end

    it 'should not call user-password-update to change password' do
      provider.expects(:auth_keystone).with('user-password-update', '--pass', 'newpassword', 'id').times(0)
      provider.password=('newpassword')
    end
  end

end
