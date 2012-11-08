require 'spec_helper'

describe 'swift::keystone::dispersion' do

  describe 'with default class parameters' do

    it { should contain_keystone_user('dispersion').with(
      :ensure   => 'present',
      :password => 'dispersion_password'
    ) }

    it { should contain_keystone_user_role('dispersion@services').with(
      :ensure  => 'present',
      :roles   => 'admin',
      :require => 'Keystone_user[dispersion]'
    ) }
  end

  describe 'when overriding password' do

    let :params do
      {
        :auth_pass => 'foo'
      }
    end

    it { should contain_keystone_user('dispersion').with(
      :ensure   => 'present',
      :password => 'foo'
    ) }

  end

  describe 'when overriding auth user' do

    let :params do
      {
        :auth_user => 'bar'
      }
    end

    it { should contain_keystone_user('bar') }

    it { should contain_keystone_user_role('bar@services') }

  end

end
