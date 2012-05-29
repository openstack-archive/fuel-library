require 'spec_helper'

describe 'swift::keystone::auth' do

  describe 'with default class parameters' do

    it { should contain_keystone_user('swift').with(
      :ensure   => 'present',
      :password => 'swift_password'
    ) }

    it { should contain_keystone_user_role('swift@services').with(
      :ensure  => 'present',
      :roles   => 'admin',
      :require => 'Keystone_user[swift]'
    )}

    it { should contain_keystone_service('swift').with(
      :ensure      => 'present',
      :type        => 'object-store',
      :description => 'Openstack Object-Store Service'
    ) }

    it { should contain_keystone_endpoint('swift').with(
      :ensure       => 'present',
      :region       => 'RegionOne',
      :public_url   => "http://127.0.0.1:8080/v1/AUTH_%(tenant_id)s",
      :admin_url    => "http://127.0.0.1:8080/",
      :internal_url => "http://127.0.0.1:8080/v1/AUTH_%(tenant_id)s"
    ) }

    it { should contain_keystone_service('swift_s3').with(
      :ensure      => 'present',
      :type        => 's3',
      :description => 'Openstack S3 Service'
    ) }

    it { should contain_keystone_endpoint('swift_s3').with(
      :ensure       => 'present',
      :region       => 'RegionOne',
      :public_url   => 'http://127.0.0.1:8080',
      :admin_url    => 'http://127.0.0.1:8080',
      :internal_url => 'http://127.0.0.1:8080'
    ) }
  end

  describe 'when overriding password' do

    let :params do
      {
        :password => 'foo'
      }
    end

    it { should contain_keystone_user('swift').with(
      :ensure   => 'present',
      :password => 'foo'
    ) } 

  end

  describe 'when overriding auth name' do

    let :params do
      {
        :auth_name => 'swifty'
      }
    end

    it { should contain_keystone_user('swifty') }

    it { should contain_keystone_user_role('swifty@services') }

    it { should contain_keystone_service('swifty') }

    it { should contain_keystone_endpoint('swifty') }

    it { should contain_keystone_service('swifty_s3') }

    it { should contain_keystone_endpoint('swifty_s3') }

  end

  describe 'when overriding address' do

    let :params do
      {
        :address => '192.168.0.1',
        :port => '8081'
      }
    end

    it { should contain_keystone_endpoint('swift').with(
      :ensure       => 'present',
      :region       => 'RegionOne',
      :public_url   => "http://192.168.0.1:8081/v1/AUTH_%(tenant_id)s",
      :admin_url    => "http://192.168.0.1:8081/",
      :internal_url => "http://192.168.0.1:8081/v1/AUTH_%(tenant_id)s"
    ) }

    it { should contain_keystone_endpoint('swift_s3').with(
      :ensure       => 'present',
      :region       => 'RegionOne',
      :public_url   => 'http://192.168.0.1:8081',
      :admin_url    => 'http://192.168.0.1:8081',
      :internal_url => 'http://192.168.0.1:8081'
    ) }

  end

end
