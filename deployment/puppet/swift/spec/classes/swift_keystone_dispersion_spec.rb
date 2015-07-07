require 'spec_helper'

describe 'swift::keystone::dispersion' do

  describe 'with default class parameters' do

    it { is_expected.to contain_keystone_user('dispersion').with(
      :ensure   => 'present',
      :password => 'dispersion_password',
      :email    => 'swift@localhost',
      :tenant   => 'services'
    ) }

    it { is_expected.to contain_keystone_user_role('dispersion@services').with(
      :ensure  => 'present',
      :roles   => 'admin',
      :require => 'Keystone_user[dispersion]'
    ) }
  end

  describe 'when overriding parameters' do

    let :params do
      {
        :auth_user => 'bar',
        :auth_pass => 'foo',
        :email     => 'bar@example.com',
        :tenant    => 'dummyTenant'
      }
    end

    it { is_expected.to contain_keystone_user('bar').with(
      :ensure   => 'present',
      :password => 'foo',
      :email    => 'bar@example.com',
      :tenant   => 'dummyTenant'
    ) }

    it { is_expected.to contain_keystone_user_role('bar@dummyTenant') }

  end

end
