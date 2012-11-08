require 'spec_helper'

describe 'glance::keystone::auth' do

  describe 'with defaults' do

    let :params do
      {:password => 'pass'}
    end

    it { should contain_keystone_user('glance').with(
      :ensure   => 'present',
      :password => 'pass'
    )}

    it { should contain_keystone_user_role('glance@services').with(
      :ensure => 'present',
      :roles  => 'admin'
    ) }

    it { should contain_keystone_service('glance').with(
      :ensure      => 'present',
      :type        => 'image',
      :description => 'Openstack Image Service'
    ) }

    it { should contain_keystone_endpoint('glance').with(
      :ensure       => 'present',
      :region       => 'RegionOne',
      :public_url   => 'http://127.0.0.1:9292/v1',
      :admin_url    => 'http://127.0.0.1:9292/v1',
      :internal_url => 'http://127.0.0.1:9292/v1'
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

    it { should contain_keystone_user('glancey').with(
      :ensure   => 'present',
      :password => 'password'
    )}

    it { should contain_keystone_user_role('glancey@services').with(
      :ensure => 'present',
      :roles  => 'admin'
    ) }

    it { should contain_keystone_service('glancey').with(
      :ensure      => 'present',
      :type        => 'imagey',
      :description => 'Openstack Image Service'
    ) }

  end

  describe 'when address, region and port are overridden' do

    let :params do
      {
        :password         => 'pass',
        :public_address   => '10.0.0.1',
        :admin_address    => '10.0.0.2',
        :internal_address => '10.0.0.3',
        :port             => '9393',
        :region           => 'RegionTwo'
      }
    end

    it { should contain_keystone_endpoint('glance').with(
      :ensure       => 'present',
      :region       => 'RegionTwo',
      :public_url   => 'http://10.0.0.1:9393/v1',
      :admin_url    => 'http://10.0.0.2:9393/v1',
      :internal_url => 'http://10.0.0.3:9393/v1'
    )}

  end

  describe 'when endpoint is not set' do

    let :params do
      {
        :configure_endpoint => false,
        :password         => 'pass',
      }
    end

    it { should_not contain_keystone_endpoint('glance') }
  end

end
