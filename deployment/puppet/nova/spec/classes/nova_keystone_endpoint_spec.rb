require 'spec_helper'

describe 'nova::keystone::auth' do

  let :params do
    {:password => 'nova_password'}
  end

  let :default_params do
    { :auth_name              => 'nova',
      :region                 => 'RegionOne',
      :tenant                 => 'services',
      :email                  => 'nova@localhost',
      :public_url             => 'http://127.0.0.1:8774/v2/%(tenant_id)s',
      :internal_url           => 'http://127.0.0.1:8774/v2/%(tenant_id)s',
      :admin_url              => 'http://127.0.0.1:8774/v2/%(tenant_id)s',
      :public_url_v3          => 'http://127.0.0.1:8774/v3',
      :internal_url_v3        => 'http://127.0.0.1:8774/v3',
      :admin_url_v3           => 'http://127.0.0.1:8774/v3',
      :configure_ec2_endpoint => true,
      :ec2_public_url         => 'http://127.0.0.1:8773/services/Cloud',
      :ec2_internal_url       => 'http://127.0.0.1:8773/services/Cloud',
      :ec2_admin_url          => 'http://127.0.0.1:8773/services/Admin' }
  end

  context 'with default parameters' do

    it { is_expected.to contain_keystone_user('nova').with(
      :ensure   => 'present',
      :password => 'nova_password'
    ) }

    it { is_expected.to contain_keystone_user_role('nova@services').with(
      :ensure => 'present',
      :roles  => ['admin']
    )}

    it { is_expected.to contain_keystone_service('nova').with(
      :ensure => 'present',
      :type        => 'compute',
      :description => 'Openstack Compute Service'
    )}

    it { is_expected.to contain_keystone_service('novav3').with(
      :ensure => 'present',
      :type        => 'computev3',
      :description => 'Openstack Compute Service v3'
    )}

    it { is_expected.to contain_keystone_service('nova_ec2').with(
      :ensure => 'present',
      :type        => 'ec2',
      :description => 'EC2 Service'
    )}

    it { is_expected.to contain_keystone_endpoint('RegionOne/nova').with(
      :ensure       => 'present',
      :public_url   => 'http://127.0.0.1:8774/v2/%(tenant_id)s',
      :admin_url    => 'http://127.0.0.1:8774/v2/%(tenant_id)s',
      :internal_url => 'http://127.0.0.1:8774/v2/%(tenant_id)s'
    )}

    it { is_expected.to contain_keystone_endpoint('RegionOne/novav3').with(
      :ensure       => 'present',
      :public_url   => 'http://127.0.0.1:8774/v3',
      :admin_url    => 'http://127.0.0.1:8774/v3',
      :internal_url => 'http://127.0.0.1:8774/v3'
    )}

    it { is_expected.to contain_keystone_endpoint('RegionOne/nova_ec2').with(
      :ensure       => 'present',
      :public_url   => 'http://127.0.0.1:8773/services/Cloud',
      :admin_url    => 'http://127.0.0.1:8773/services/Admin',
      :internal_url => 'http://127.0.0.1:8773/services/Cloud'
    )}

  end

  context 'when setting auth name' do
    before do
      params.merge!( :auth_name => 'foo' )
    end

    it { is_expected.to contain_keystone_user('foo').with(
      :ensure   => 'present',
      :password => 'nova_password'
    ) }

    it { is_expected.to contain_keystone_user_role('foo@services').with(
      :ensure => 'present',
      :roles  => ['admin']
    )}

    it { is_expected.to contain_keystone_service('foo').with(
      :ensure      => 'present',
      :type        => 'compute',
      :description => 'Openstack Compute Service'
    )}

    it { is_expected.to contain_keystone_service('foo_ec2').with(
      :ensure     => 'present',
      :type        => 'ec2',
      :description => 'EC2 Service'
    )}

  end

  context 'when setting auth_name and auth_name_v3 the same' do
    before do
      params.merge!(
        :auth_name        => 'thesame',
        :auth_name_v3     => 'thesame',
        :service_name     => 'nova',
        :service_name_v3  => 'novav3',
      )
    end

    it { is_expected.to contain_keystone_user('thesame').with(:ensure => 'present') }
    it { is_expected.to contain_keystone_user_role('thesame@services').with(:ensure => 'present') }
    it { is_expected.to contain_keystone_service('nova').with(:ensure => 'present') }
    it { is_expected.to contain_keystone_service('novav3').with(:ensure => 'present') }

  end

  context 'when service_name and service_name_3 the same (by explicitly setting them)' do
    before do
      params.merge!(
        :service_name     => 'nova',
        :service_name_v3  => 'nova'
      )
    end

    it do
      expect { is_expected.to contain_keystone_service('nova') }.to raise_error(Puppet::Error, /service_name and service_name_v3 must be different/)
    end

  end

  context 'when service_name and service_name_3 the same (by implicit declaration via auth_name and auth_name_v3)' do
    before do
      params.merge!(
        :auth_name        => 'thesame',
        :auth_name_v3     => 'thesame',
      )
    end

    it do
      expect { is_expected.to contain_keystone_service('nova') }.to raise_error(Puppet::Error, /service_name and service_name_v3 must be different/)
    end

  end

  context 'when overriding endpoint parameters' do
    before do
      params.merge!(
        :region            => 'RegionTwo',
        :public_url        => 'https://10.0.0.1:9774/v2.2/%(tenant_id)s',
        :internal_url      => 'https://10.0.0.3:9774/v2.2/%(tenant_id)s',
        :admin_url         => 'https://10.0.0.2:9774/v2.2/%(tenant_id)s',
        :public_url_v3     => 'https://10.0.3.1:9774/v3',
        :internal_url_v3   => 'https://10.0.3.3:9774/v3',
        :admin_url_v3      => 'https://10.0.3.2:9774/v3',
        :ec2_public_url    => 'https://10.0.9.1:9773/services/Cloud',
        :ec2_internal_url  => 'https://10.0.9.2:9773/services/Cloud',
        :ec2_admin_url     => 'https://10.0.9.3:9773/services/Admin',
      )
    end

    it { is_expected.to contain_keystone_endpoint('RegionTwo/nova').with(
      :ensure       => 'present',
      :public_url   => params[:public_url],
      :internal_url => params[:internal_url],
      :admin_url    => params[:admin_url]
    )}

    it { is_expected.to contain_keystone_endpoint('RegionTwo/novav3').with(
      :ensure       => 'present',
      :public_url   => params[:public_url_v3],
      :internal_url => params[:internal_url_v3],
      :admin_url    => params[:admin_url_v3]
    )}

    it { is_expected.to contain_keystone_endpoint('RegionTwo/nova_ec2').with(
      :ensure       => 'present',
      :public_url   => params[:ec2_public_url],
      :internal_url => params[:ec2_internal_url],
      :admin_url    => params[:ec2_admin_url]
    )}
  end

  context 'when providing deprecated endpoint parameters' do
    before do
      params.merge!(
        :public_address    => '10.0.0.1',
        :admin_address     => '10.0.0.2',
        :internal_address  => '10.0.0.3',
        :compute_port      => '9774',
        :ec2_port          => '9773',
        :compute_version   => 'v2.2',
        :region            => 'RegionTwo',
        :admin_protocol    => 'https',
        :internal_protocol => 'https',
        :public_protocol   => 'https'
      )
    end

    it { is_expected.to contain_keystone_endpoint('RegionTwo/nova').with(
      :ensure       => 'present',
      :public_url   => 'https://10.0.0.1:9774/v2.2/%(tenant_id)s',
      :admin_url    => 'https://10.0.0.2:9774/v2.2/%(tenant_id)s',
      :internal_url => 'https://10.0.0.3:9774/v2.2/%(tenant_id)s'
    )}

    it { is_expected.to contain_keystone_endpoint('RegionTwo/nova_ec2').with(
      :ensure       => 'present',
      :public_url   => 'https://10.0.0.1:9773/services/Cloud',
      :admin_url    => 'https://10.0.0.2:9773/services/Admin',
      :internal_url => 'https://10.0.0.3:9773/services/Cloud'
    )}
  end

  describe 'when disabling endpoint configuration' do
    before do
      params.merge!( :configure_endpoint => false )
    end

    it { is_expected.to_not contain_keystone_endpoint('RegionOne/nova') }
  end

  describe 'when disabling EC2 endpoint' do
    before do
      params.merge!( :configure_ec2_endpoint => false )
    end

    it { is_expected.to_not contain_keystone_service('nova_ec2') }
    it { is_expected.to_not contain_keystone_endpoint('RegionOne/nova_ec2') }
  end

  describe 'when disabling user configuration' do
    before do
      params.merge!( :configure_user => false )
    end

    it { is_expected.to_not contain_keystone_user('nova') }
    it { is_expected.to contain_keystone_user_role('nova@services') }
    it { is_expected.to contain_keystone_service('nova').with(
      :ensure => 'present',
      :type        => 'compute',
      :description => 'Openstack Compute Service'
    )}
  end

  describe 'when disabling user and user role configuration' do
    let :params do
      {
        :configure_user      => false,
        :configure_user_role => false,
        :password            => 'nova_password'
      }
    end

    it { is_expected.to_not contain_keystone_user('nova') }
    it { is_expected.to_not contain_keystone_user_role('nova@services') }
    it { is_expected.to contain_keystone_service('nova').with(
      :ensure => 'present',
      :type        => 'compute',
      :description => 'Openstack Compute Service'
    )}
  end

  describe 'when configuring nova-api and the keystone endpoint' do
    let :pre_condition do
      "class { 'nova::api': admin_password => 'test' }
      include nova"
    end

    let :facts do
      { :osfamily => "Debian"}
    end

    let :params do
      {
        :password => 'test'
      }
    end

    it { is_expected.to contain_keystone_endpoint('RegionOne/nova').with_notify(['Service[nova-api]']) }
  end

  describe 'when overriding service names' do

    let :params do
      {
        :service_name    => 'nova_service',
        :service_name_v3 => 'nova_service_v3',
        :password        => 'nova_password'
      }
    end

    it { is_expected.to contain_keystone_user('nova') }
    it { is_expected.to contain_keystone_user_role('nova@services') }
    it { is_expected.to contain_keystone_service('nova_service') }
    it { is_expected.to contain_keystone_service('nova_service_v3') }
    it { is_expected.to contain_keystone_service('nova_service_ec2') }
    it { is_expected.to contain_keystone_endpoint('RegionOne/nova_service') }
    it { is_expected.to contain_keystone_endpoint('RegionOne/nova_service_v3') }
    it { is_expected.to contain_keystone_endpoint('RegionOne/nova_service_ec2') }

  end

end

