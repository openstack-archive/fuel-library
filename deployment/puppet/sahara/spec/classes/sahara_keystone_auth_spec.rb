#
# Unit tests for sahara::keystone::auth
#
require 'spec_helper'

describe 'sahara::keystone::auth' do

  let :facts do
    { :osfamily => 'Debian' }
  end

  describe 'with default class parameters' do
    let :params do
      { :password => 'sahara_password',
        :tenant   => 'foobar' }
    end

    it { is_expected.to contain_keystone_user('sahara').with(
      :ensure   => 'present',
      :password => 'sahara_password',
      :tenant   => 'foobar'
    ) }

    it { is_expected.to contain_keystone_user_role('sahara@foobar').with(
      :ensure  => 'present',
      :roles   => ['admin']
    )}

    it { is_expected.to contain_keystone_service('sahara').with(
      :ensure      => 'present',
      :type        => 'data-processing',
      :description => 'Sahara Data Processing'
    ) }

    it { is_expected.to contain_keystone_endpoint('RegionOne/sahara').with(
      :ensure       => 'present',
      :public_url   => "http://127.0.0.1:8386/v1.1/%(tenant_id)s",
      :admin_url    => "http://127.0.0.1:8386/v1.1/%(tenant_id)s",
      :internal_url => "http://127.0.0.1:8386/v1.1/%(tenant_id)s"
    ) }
  end

  describe 'when configuring sahara-server' do
    let :pre_condition do
      "class { 'sahara::server': auth_password => 'test' }"
    end

    let :params do
      { :password => 'sahara_password',
        :tenant   => 'foobar' }
    end
  end

  describe 'with endpoint parameters' do
    let :params do
      { :password     => 'sahara_password',
        :public_url   => 'https://10.10.10.10:80/v1.1/%(tenant_id)s',
        :internal_url => 'http://10.10.10.11:81/v1.1/%(tenant_id)s',
        :admin_url    => 'http://10.10.10.12:81/v1.1/%(tenant_id)s' }
    end

    it { is_expected.to contain_keystone_endpoint('RegionOne/sahara').with(
      :ensure       => 'present',
      :public_url   => 'https://10.10.10.10:80/v1.1/%(tenant_id)s',
      :internal_url => 'http://10.10.10.11:81/v1.1/%(tenant_id)s',
      :admin_url    => 'http://10.10.10.12:81/v1.1/%(tenant_id)s'
    ) }
  end

  describe 'with deprecated endpoint parameters' do
    let :params do
      { :password         => 'sahara_password',
        :public_protocol  => 'https',
        :public_port      => '80',
        :public_address   => '10.10.10.10',
        :port             => '81',
        :internal_address => '10.10.10.11',
        :admin_address    => '10.10.10.12' }
    end

    it { is_expected.to contain_keystone_endpoint('RegionOne/sahara').with(
      :ensure       => 'present',
      :public_url   => "https://10.10.10.10:80/v1.1/%(tenant_id)s",
      :internal_url => "http://10.10.10.11:81/v1.1/%(tenant_id)s",
      :admin_url    => "http://10.10.10.12:81/v1.1/%(tenant_id)s"
    ) }
  end

  describe 'when overriding auth name' do
    let :params do
      { :password => 'foo',
        :auth_name => 'saharay' }
    end

    it { is_expected.to contain_keystone_user('saharay') }
    it { is_expected.to contain_keystone_user_role('saharay@services') }
    it { is_expected.to contain_keystone_service('saharay') }
    it { is_expected.to contain_keystone_endpoint('RegionOne/saharay') }
  end
end
