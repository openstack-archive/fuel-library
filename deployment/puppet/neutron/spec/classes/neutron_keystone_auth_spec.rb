require 'spec_helper'

describe 'neutron::keystone::auth' do

  describe 'with default class parameters' do
    let :params do
      {
        :password => 'neutron_password',
        :tenant   => 'foobar'
      }
    end

    it { should contain_keystone_user('neutron').with(
      :ensure   => 'present',
      :password => 'neutron_password',
      :tenant   => 'foobar'
    ) }

    it { should contain_keystone_user_role('neutron@foobar').with(
      :ensure  => 'present',
      :roles   => 'admin'
    )}

    it { should contain_keystone_service('neutron').with(
      :ensure      => 'present',
      :type        => 'network',
      :description => 'Neutron Networking Service'
    ) }

    it { should contain_keystone_endpoint('RegionOne/neutron').with(
      :ensure       => 'present',
      :public_url   => "http://127.0.0.1:9696/",
      :admin_url    => "http://127.0.0.1:9696/",
      :internal_url => "http://127.0.0.1:9696/"
    ) }

  end

  describe 'when configuring neutron-server' do
    let :pre_condition do
      "class { 'neutron::server': auth_password => 'test' }"
    end

    let :facts do
      { :osfamily => 'Debian' }
    end

    let :params do
      {
        :password => 'neutron_password',
        :tenant   => 'foobar'
      }
    end

    it { should contain_keystone_endpoint('RegionOne/neutron').with_notify('Service[neutron-server]') }
  end

  describe 'when overriding public_protocol, public_port and public address' do

    let :params do
      {
        :password         => 'neutron_password',
        :public_protocol  => 'https',
        :public_port      => '80',
        :public_address   => '10.10.10.10',
        :port             => '81',
        :internal_address => '10.10.10.11',
        :admin_address    => '10.10.10.12'
      }
    end

    it { should contain_keystone_endpoint('RegionOne/neutron').with(
      :ensure       => 'present',
      :public_url   => "https://10.10.10.10:80/",
      :internal_url => "http://10.10.10.11:81/",
      :admin_url    => "http://10.10.10.12:81/"
    ) }

  end

  describe 'when overriding admin_protocol and internal_protocol' do

    let :params do
      {
        :password          => 'neutron_password',
        :admin_protocol    => 'https',
        :internal_protocol => 'https',
      }
    end

    it { should contain_keystone_endpoint('RegionOne/neutron').with(
      :ensure       => 'present',
      :public_url   => "http://127.0.0.1:9696/",
      :admin_url    => "https://127.0.0.1:9696/",
      :internal_url => "https://127.0.0.1:9696/"
    ) }

  end

  describe 'when overriding auth name' do

    let :params do
      {
        :password => 'foo',
        :auth_name => 'neutrony'
      }
    end

    it { should contain_keystone_user('neutrony') }

    it { should contain_keystone_user_role('neutrony@services') }

    it { should contain_keystone_service('neutrony') }

    it { should contain_keystone_endpoint('RegionOne/neutrony') }

  end

  describe 'when overriding service name' do

    let :params do
      {
        :service_name => 'neutron_service',
        :password     => 'neutron_password'
      }
    end

    it { should contain_keystone_user('neutron') }
    it { should contain_keystone_user_role('neutron@services') }
    it { should contain_keystone_service('neutron_service') }
    it { should contain_keystone_endpoint('RegionOne/neutron_service') }

  end

  describe 'when disabling user configuration' do

    let :params do
      {
        :password       => 'neutron_password',
        :configure_user => false
      }
    end

    it { should_not contain_keystone_user('neutron') }

    it { should contain_keystone_user_role('neutron@services') }

    it { should contain_keystone_service('neutron').with(
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

    it { should_not contain_keystone_user('neutron') }

    it { should_not contain_keystone_user_role('neutron@services') }

    it { should contain_keystone_service('neutron').with(
      :ensure      => 'present',
      :type        => 'network',
      :description => 'Neutron Networking Service'
    ) }

  end

end
