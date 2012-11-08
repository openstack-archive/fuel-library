require 'spec_helper'

describe 'nova::keystone::auth' do

  describe 'with defaults' do

    let :params do
      {:password => 'nova_password'}
    end

    it { should contain_keystone_user('nova').with(
      :ensure   => 'present',
      :password => 'nova_password'
    ) }

    it { should contain_keystone_user_role('nova@services').with(
      :ensure => 'present',
      :roles  => 'admin'
    )}

    it { should contain_keystone_service('nova').with(
      :ensure => 'present',
      :type        => 'compute',
      :description => 'Openstack Compute Service'
    )}

    it { should contain_keystone_service('nova_volume').with(
      :ensure => 'present',
      :type        => 'volume',
      :description => 'Volume Service'
    )}

    it { should contain_keystone_service('nova_ec2').with(
      :ensure => 'present',
      :type        => 'ec2',
      :description => 'EC2 Service'
    )}

    it { should contain_keystone_endpoint('nova').with(
      :ensure       => 'present',
      :region       => 'RegionOne',
      :public_url   => 'http://127.0.0.1:8774/v2/%(tenant_id)s',
      :admin_url    => 'http://127.0.0.1:8774/v2/%(tenant_id)s',
      :internal_url => 'http://127.0.0.1:8774/v2/%(tenant_id)s'
    )}

    it { should contain_keystone_endpoint('nova_volume').with(
      :ensure       => 'present',
      :region       => 'RegionOne',
      :public_url   => 'http://127.0.0.1:8776/v1/%(tenant_id)s',
      :admin_url    => 'http://127.0.0.1:8776/v1/%(tenant_id)s',
      :internal_url => 'http://127.0.0.1:8776/v1/%(tenant_id)s'
    )}

    it { should contain_keystone_endpoint('nova_ec2').with(
      :ensure       => 'present',
      :region       => 'RegionOne',
      :public_url   => 'http://127.0.0.1:8773/services/Cloud',
      :admin_url    => 'http://127.0.0.1:8773/services/Admin',
      :internal_url => 'http://127.0.0.1:8773/services/Cloud'
    )}

  end

  describe 'when setting auth name' do

    let :params do
      {:password => 'nova_password', :auth_name => 'foo' }
    end

    it { should contain_keystone_user('foo').with(
      :ensure   => 'present',
      :password => 'nova_password'
    ) }

    it { should contain_keystone_user_role('foo@services').with(
      :ensure => 'present',
      :roles  => 'admin'
    )}

    it { should contain_keystone_service('foo').with(
      :ensure      => 'present',
      :type        => 'compute',
      :description => 'Openstack Compute Service'
    )}

    it { should contain_keystone_service('foo_volume').with(
      :ensure      => 'present',
      :type        => 'volume',
      :description => 'Volume Service'
    )}

    it { should contain_keystone_service('foo_ec2').with(
      :ensure     => 'present',
      :type        => 'ec2',
      :description => 'EC2 Service'
    )}

  end

  describe 'when setting password' do

    let :params do
      { :password => 'pass'}
    end

    it { should contain_keystone_user('nova').with(
      :ensure   => 'present',
      :password => 'pass'
    ) }

  end


  describe 'when overriding endpoint params' do

    let :params do
      {
        :password         => 'nova_password',
        :public_address   => '10.0.0.1',
        :admin_address    => '10.0.0.2',
        :internal_address => '10.0.0.3',
        :compute_port     => '9774',
        :volume_port      => '9776',
        :ec2_port         => '9773',
        :volume_version   => 'v2.1',
        :compute_version  => 'v2.2',
        :region           => 'RegionTwo'
      }
    end

    it { should contain_keystone_endpoint('nova').with(
      :ensure       => 'present',
      :region       => 'RegionTwo',
      :public_url   => 'http://10.0.0.1:9774/v2.2/%(tenant_id)s',
      :admin_url    => 'http://10.0.0.2:9774/v2.2/%(tenant_id)s',
      :internal_url => 'http://10.0.0.3:9774/v2.2/%(tenant_id)s'
    )}

    it { should contain_keystone_endpoint('nova_volume').with(
      :ensure       => 'present',
      :region       => 'RegionTwo',
      :public_url   => 'http://10.0.0.1:9776/v2.1/%(tenant_id)s',
      :admin_url    => 'http://10.0.0.2:9776/v2.1/%(tenant_id)s',
      :internal_url => 'http://10.0.0.3:9776/v2.1/%(tenant_id)s'
    )}

    it { should contain_keystone_endpoint('nova_ec2').with(
      :ensure       => 'present',
      :region       => 'RegionTwo',
      :public_url   => 'http://10.0.0.1:9773/services/Cloud',
      :admin_url    => 'http://10.0.0.2:9773/services/Admin',
      :internal_url => 'http://10.0.0.3:9773/services/Cloud'
    )}

  end

end
