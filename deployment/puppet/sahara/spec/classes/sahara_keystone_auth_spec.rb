require 'spec_helper'

describe 'sahara::keystone::auth' do

  describe 'with defaults' do

    let :params do
      {:password => 'pass'}
    end

    it { is_expected.to contain_keystone_user('sahara').with(
      :ensure   => 'present',
      :password => 'pass'
    )}

    it { is_expected.to contain_keystone_user_role('sahara@services').with(
      :ensure => 'present',
      :roles  => ['admin']
    ) }

    it { is_expected.to contain_keystone_service('sahara').with(
      :ensure      => 'present',
      :type        => 'sahara',
      :description => 'OpenStack Data Processing'
    ) }

    it { is_expected.to contain_keystone_endpoint('RegionOne/sahara').with(
      :ensure       => 'present',
      :public_url   => 'http://127.0.0.1:8386/v1.1/%(tenant_id)s',
      :admin_url    => 'http://127.0.0.1:8386/v1.1/%(tenant_id)s',
      :internal_url => 'http://127.0.0.1:8386/v1.1/%(tenant_id)s'
    )}

  end

  describe 'when auth_type, password, and service_type are overridden' do

    let :params do
      {
        :auth_name    => 'saharas',
        :password     => 'password',
        :service_type => 'saharay'
      }
    end

    it { is_expected.to contain_keystone_user('saharas').with(
      :ensure   => 'present',
      :password => 'password'
    )}

    it { is_expected.to contain_keystone_user_role('saharas@services').with(
      :ensure => 'present',
      :roles  => ['admin']
    ) }

    it { is_expected.to contain_keystone_service('saharas').with(
      :ensure      => 'present',
      :type        => 'saharay',
      :description => 'OpenStack Data Processing'
    ) }

  end

  describe 'when overriding endpoint URLs' do
    let :params do
      { :password         => 'passw0rd',
        :region           => 'RegionTwo',
        :public_url       => 'http://10.10.0.1:8386/v1.1/%(tenant_id)s',
        :internal_url     => 'http://10.10.0.1:8386/v1.1/%(tenant_id)s',
        :admin_url        => 'http://10.10.0.1:8386/v1.1/%(tenant_id)s' }
    end

    it { is_expected.to contain_keystone_endpoint('RegionTwo/sahara').with(
      :ensure       => 'present',
      :public_url   => 'http://10.10.0.1:8386/v1.1/%(tenant_id)s',
      :internal_url => 'http://10.10.0.1:8386/v1.1/%(tenant_id)s',
      :admin_url    => 'http://10.10.0.1:8386/v1.1/%(tenant_id)s'
    ) }
  end

  describe 'with deprecated endpoints parameters' do

    let :params do
      {
        :password          => 'pass',
        :public_address    => '10.10.0.1',
        :admin_address     => '10.10.0.2',
        :internal_address  => '10.10.0.3',
        :port              => '8386',
        :region            => 'RegionTwo',
        :public_protocol   => 'https',
        :admin_protocol    => 'https',
        :internal_protocol => 'https'
      }
    end

    it { is_expected.to contain_keystone_endpoint('RegionTwo/sahara').with(
      :ensure       => 'present',
      :public_url   => 'https://10.10.0.1:8386/v1.1/%(tenant_id)s',
      :admin_url    => 'https://10.10.0.2:8386/v1.1/%(tenant_id)s',
      :internal_url => 'https://10.10.0.3:8386/v1.1/%(tenant_id)s'
    )}

  end

  describe 'when endpoint is not set' do

    let :params do
      {
        :configure_endpoint => false,
        :password         => 'pass',
      }
    end

    it { is_expected.to_not contain_keystone_endpoint('RegionOne/sahara') }
  end

  describe 'when disabling user configuration' do
    let :params do
      {
        :configure_user => false,
        :password       => 'pass',
      }
    end

    it { is_expected.to_not contain_keystone_user('sahara') }

    it { is_expected.to contain_keystone_user_role('sahara@services') }

    it { is_expected.to contain_keystone_service('sahara').with(
      :ensure      => 'present',
      :type        => 'sahara',
      :description => 'OpenStack Data Processing'
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

    it { is_expected.to_not contain_keystone_user('sahara') }

    it { is_expected.to_not contain_keystone_user_role('sahara@services') }

    it { is_expected.to contain_keystone_service('sahara').with(
      :ensure      => 'present',
      :type        => 'sahara',
      :description => 'OpenStack Data Processing'
    ) }
  end

  describe 'when overriding service name' do

    let :params do
      {
        :service_name => 'sahara_service',
        :password     => 'pass'
      }
    end

    it { is_expected.to contain_keystone_user('sahara') }
    it { is_expected.to contain_keystone_user_role('sahara@services') }
    it { is_expected.to contain_keystone_service('sahara_service') }
    it { is_expected.to contain_keystone_endpoint('RegionOne/sahara_service') }

  end

end
