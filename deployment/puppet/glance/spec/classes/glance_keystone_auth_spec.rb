require 'spec_helper'

describe 'glance::keystone::auth' do

  describe 'with defaults' do

    let :params do
      {:password => 'pass'}
    end

    it { is_expected.to contain_keystone_user('glance').with(
      :ensure   => 'present',
      :password => 'pass'
    )}

    it { is_expected.to contain_keystone_user_role('glance@services').with(
      :ensure => 'present',
      :roles  => ['admin']
    ) }

    it { is_expected.to contain_keystone_service('glance').with(
      :ensure      => 'present',
      :type        => 'image',
      :description => 'OpenStack Image Service'
    ) }

    it { is_expected.to contain_keystone_endpoint('RegionOne/glance').with(
      :ensure       => 'present',
      :public_url   => 'http://127.0.0.1:9292',
      :admin_url    => 'http://127.0.0.1:9292',
      :internal_url => 'http://127.0.0.1:9292'
    )}

  end

  describe 'when auth_type, password, and service_type are overridden' do

    let :params do
      {
        :auth_name    => 'glancey',
        :password     => 'password',
        :service_type => 'imagey'
      }
    end

    it { is_expected.to contain_keystone_user('glancey').with(
      :ensure   => 'present',
      :password => 'password'
    )}

    it { is_expected.to contain_keystone_user_role('glancey@services').with(
      :ensure => 'present',
      :roles  => ['admin']
    ) }

    it { is_expected.to contain_keystone_service('glancey').with(
      :ensure      => 'present',
      :type        => 'imagey',
      :description => 'OpenStack Image Service'
    ) }

  end

  describe 'when overriding endpoint URLs' do
    let :params do
      { :password         => 'passw0rd',
        :region            => 'RegionTwo',
        :public_url       => 'https://10.10.10.10:81/v2',
        :internal_url     => 'https://10.10.10.11:81/v2',
        :admin_url        => 'https://10.10.10.12:81/v2' }
    end

    it { is_expected.to contain_keystone_endpoint('RegionTwo/glance').with(
      :ensure       => 'present',
      :public_url   => 'https://10.10.10.10:81/v2',
      :internal_url => 'https://10.10.10.11:81/v2',
      :admin_url    => 'https://10.10.10.12:81/v2'
    ) }
  end

  describe 'with deprecated endpoints parameters' do

    let :params do
      {
        :password          => 'pass',
        :public_address    => '10.0.0.1',
        :admin_address     => '10.0.0.2',
        :internal_address  => '10.0.0.3',
        :port              => '9393',
        :region            => 'RegionTwo',
        :public_protocol   => 'https',
        :admin_protocol    => 'https',
        :internal_protocol => 'https'
      }
    end

    it { is_expected.to contain_keystone_endpoint('RegionTwo/glance').with(
      :ensure       => 'present',
      :public_url   => 'https://10.0.0.1:9393',
      :admin_url    => 'https://10.0.0.2:9393',
      :internal_url => 'https://10.0.0.3:9393'
    )}

  end

  describe 'when endpoint is not set' do

    let :params do
      {
        :configure_endpoint => false,
        :password         => 'pass',
      }
    end

    it { is_expected.to_not contain_keystone_endpoint('RegionOne/glance') }
  end

  describe 'when disabling user configuration' do
    let :params do
      {
        :configure_user => false,
        :password       => 'pass',
      }
    end

    it { is_expected.to_not contain_keystone_user('glance') }

    it { is_expected.to contain_keystone_user_role('glance@services') }

    it { is_expected.to contain_keystone_service('glance').with(
      :ensure      => 'present',
      :type        => 'image',
      :description => 'OpenStack Image Service'
    ) }
  end

  describe 'when disabling user and user role configuration' do
    let :params do
      {
        :configure_user      => false,
        :configure_user_role => false,
        :password            => 'pass',
      }
    end

    it { is_expected.to_not contain_keystone_user('glance') }

    it { is_expected.to_not contain_keystone_user_role('glance@services') }

    it { is_expected.to contain_keystone_service('glance').with(
      :ensure      => 'present',
      :type        => 'image',
      :description => 'OpenStack Image Service'
    ) }
  end

  describe 'when configuring glance-api and the keystone endpoint' do
    let :pre_condition do
      "class { 'glance::api': keystone_password => 'test' }"
    end

    let :facts do
      { :osfamily => 'Debian' }
    end

    let :params do
      {
        :password => 'test',
        :configure_endpoint => true
      }
    end

    it { is_expected.to contain_keystone_endpoint('RegionOne/glance').with_notify(["Service[glance-api]"]) }
    end

  describe 'when overriding service name' do

    let :params do
      {
        :service_name => 'glance_service',
        :password     => 'pass'
      }
    end

    it { is_expected.to contain_keystone_user('glance') }
    it { is_expected.to contain_keystone_user_role('glance@services') }
    it { is_expected.to contain_keystone_service('glance_service') }
    it { is_expected.to contain_keystone_endpoint('RegionOne/glance_service') }

  end

end
