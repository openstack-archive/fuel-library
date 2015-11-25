require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-cinder/openstack-cinder.pp'

describe manifest do
  shared_examples 'catalog' do

  max_pool_size = 20
  max_retries = '-1'
  max_overflow = 20
  rabbit_ha_queues = Noop.hiera('rabbit_ha_queues')
  cinder_user = Noop.hiera_structure('cinder/user', "cinder")
  cinder_user_password = Noop.hiera_structure('cinder/user_password')
  cinder_tenant = Noop.hiera_structure('cinder/tenant', "services")

  it 'ensures cinder_config contains "oslo_messaging_rabbit/rabbit_ha_queues" ' do
    should contain_cinder_config('oslo_messaging_rabbit/rabbit_ha_queues').with(
      'value' => rabbit_ha_queues,
    )
  end

  it 'should declare ::cinder class with correct database_max_* parameters' do
    should contain_class('cinder').with(
      'database_max_pool_size' => max_pool_size,
      'database_max_retries'   => max_retries,
      'database_max_overflow'  => max_overflow,
    )
  end

  if Noop.hiera_structure('use_ssl', false)
    internal_auth_protocol = 'https'
    keystone_auth_host = Noop.hiera_structure('use_ssl/keystone_internal_hostname')
  else
    internal_auth_protocol = 'http'
    keystone_auth_host = Noop.hiera 'service_endpoint'
  end
    auth_uri           = "#{internal_auth_protocol}://#{keystone_auth_host}:5000/"
    identity_uri       = "#{internal_auth_protocol}://#{keystone_auth_host}:5000/"

  it 'ensures cinder_config contains auth_uri and identity_uri ' do
      should contain_cinder_config('keystone_authtoken/auth_uri').with(:value  => auth_uri)
      should contain_cinder_config('keystone_authtoken/identity_uri').with(:value  => identity_uri)
  end

  it 'ensures cinder_config contains correct values' do
    case facts[:operatingsystem]
    when 'Ubuntu'
      lock_path = '/var/lock/cinder'
    when 'CentOS'
      lock_path = '/var/lib/cinder/tmp'
    end

    should contain_cinder_config('DEFAULT/lock_path').with(:value  => lock_path)
  end

  it 'ensures cinder_config contains use_stderr set to false' do
    should contain_cinder_config('DEFAULT/use_stderr').with(:value  => 'false')
  end

  it "should contain cinder config with privileged user settings" do
    should contain_cinder_config('DEFAULT/os_privileged_user_password').with_value(cinder_user_password)
    should contain_cinder_config('DEFAULT/os_privileged_user_tenant').with_value(cinder_tenant)
    should contain_cinder_config('DEFAULT/os_privileged_user_auth_url').with_value("#{internal_auth_protocol}://#{keystone_auth_host}:5000/")
    should contain_cinder_config('DEFAULT/os_privileged_user_name').with_value(cinder_user)
    should contain_cinder_config('DEFAULT/nova_catalog_admin_info').with_value('compute:nova:adminURL')
    should contain_cinder_config('DEFAULT/nova_catalog_info').with_value('compute:nova:internalURL')
  end

  use_ceph = Noop.hiera_structure('storage/images_ceph')
  ubuntu_tgt_service_name = 'tgt'
  ubuntu_tgt_package_name = 'tgt'

  it 'ensures tgt is installed and stopped om Ubuntu with ceph' do
    if facts[:operatingsystem] == 'Ubuntu' and use_ceph
      should contain_package(ubuntu_tgt_package_name).that_comes_before('Class[cinder::volume]')
      should contain_service(ubuntu_tgt_service_name).with(
        'enable' => 'false',
        'ensure' => 'stopped',
      )
    end
  end

  end # end of shared_examples

 test_ubuntu_and_centos manifest

end
