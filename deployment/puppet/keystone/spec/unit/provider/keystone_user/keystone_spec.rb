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
      provider_class.expects(:build_user_hash).returns(
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
end

