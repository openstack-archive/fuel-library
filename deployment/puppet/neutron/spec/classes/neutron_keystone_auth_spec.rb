require 'spec_helper'

describe 'neutron::keystone::auth' do

  let :default_facts do
    { :operatingsystem           => 'default',
      :operatingsystemrelease    => 'default'
    }
  end

  describe 'with default class parameters' do
    let :params do
      {
        :password => 'neutron_password',
        :tenant   => 'foobar'
      }
    end

    it { is_expected.to contain_keystone_user('neutron').with(
      :ensure   => 'present',
      :password => 'neutron_password',
      :tenant   => 'foobar'
    ) }

    it { is_expected.to contain_keystone_user_role('neutron@foobar').with(
      :ensure  => 'present',
      :roles   => ['admin']
    )}

    it { is_expected.to contain_keystone_service('neutron').with(
      :ensure      => 'present',
      :type        => 'network',
      :description => 'Neutron Networking Service'
    ) }

    it { is_expected.to contain_keystone_endpoint('RegionOne/neutron').with(
      :ensure       => 'present',
      :public_url   => "http://127.0.0.1:9696",
      :admin_url    => "http://127.0.0.1:9696",
      :internal_url => "http://127.0.0.1:9696"
    ) }

  end

  describe 'when configuring neutron-server' do
    let :pre_condition do
      "class { 'neutron::server': auth_password => 'test' }"
    end

    let :facts do
      default_facts.merge({ :osfamily => 'Debian' })
    end

    let :params do
      {
        :password => 'neutron_password',
        :tenant   => 'foobar'
      }
    end

    it { is_expected.to contain_keystone_endpoint('RegionOne/neutron').with_notify(['Service[neutron-server]']) }
  end

  describe 'with endpoint URL parameters' do
    let :params do
      {
        :password     => 'neutron_password',
        :public_url   => 'https://10.10.10.10:80',
        :internal_url => 'https://10.10.10.11:81',
        :admin_url    => 'https://10.10.10.12:81'
      }
    end

    it { is_expected.to contain_keystone_endpoint('RegionOne/neutron').with(
      :ensure       => 'present',
      :public_url   => 'https://10.10.10.10:80',
      :internal_url => 'https://10.10.10.11:81',
      :admin_url    => 'https://10.10.10.12:81'
    ) }
  end

  describe 'with deprecated endpoint parameters' do
    let :params do
      {
        :password          => 'neutron_password',
        :public_protocol   => 'https',
        :public_port       => '80',
        :public_address    => '10.10.10.10',
        :port              => '81',
        :internal_protocol => 'https',
        :internal_address  => '10.10.10.11',
        :admin_protocol    => 'https',
        :admin_address     => '10.10.10.12'
      }
    end

    it { is_expected.to contain_keystone_endpoint('RegionOne/neutron').with(
      :ensure       => 'present',
      :public_url   => "https://10.10.10.10:80",
      :internal_url => "https://10.10.10.11:81",
      :admin_url    => "https://10.10.10.12:81"
    ) }
  end

  describe 'when overriding auth name' do

    let :params do
      {
        :password => 'foo',
        :auth_name => 'neutrony'
      }
    end

    it { is_expected.to contain_keystone_user('neutrony') }

    it { is_expected.to contain_keystone_user_role('neutrony@services') }

    it { is_expected.to contain_keystone_service('neutrony') }

    it { is_expected.to contain_keystone_endpoint('RegionOne/neutrony') }

  end

  describe 'when overriding service name' do

    let :params do
      {
        :service_name => 'neutron_service',
        :password     => 'neutron_password'
      }
    end

    it { is_expected.to contain_keystone_user('neutron') }
    it { is_expected.to contain_keystone_user_role('neutron@services') }
    it { is_expected.to contain_keystone_service('neutron_service') }
    it { is_expected.to contain_keystone_endpoint('RegionOne/neutron_service') }

  end

  describe 'when disabling user configuration' do

    let :params do
      {
        :password       => 'neutron_password',
        :configure_user => false
      }
    end

    it { is_expected.not_to contain_keystone_user('neutron') }

    it { is_expected.to contain_keystone_user_role('neutron@services') }

    it { is_expected.to contain_keystone_service('neutron').with(
      :ensure      => 'present',
      :type        => 'network',
      :description => 'Neutron Networking Service'
    ) }

  end

  describe 'when disabling user and user role configuration' do

    let :params do
      {
        :password            => 'neutron_password',
        :configure_user      => false,
        :configure_user_role => false
      }
    end

    it { is_expected.not_to contain_keystone_user('neutron') }

    it { is_expected.not_to contain_keystone_user_role('neutron@services') }

    it { is_expected.to contain_keystone_service('neutron').with(
      :ensure      => 'present',
      :type        => 'network',
      :description => 'Neutron Networking Service'
    ) }

  end

  describe 'when disabling endpoint configuration' do

    let :params do
      {
        :password           => 'neutron_password',
        :configure_endpoint => false
      }
    end

    it { is_expected.to_not contain_keystone_endpoint('RegionOne/neutron') }

  end

end
