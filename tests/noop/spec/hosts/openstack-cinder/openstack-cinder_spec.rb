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
  let(:memcached_servers) { Noop.hiera 'memcached_servers' }

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

  keystone_auth_host = Noop.hiera 'service_endpoint'
  auth_uri           = "http://#{keystone_auth_host}:5000/"
  identity_uri       = "http://#{keystone_auth_host}:5000/"

  it 'ensures cinder_config contains auth_uri and identity_uri ' do
      should contain_cinder_config('keystone_authtoken/auth_uri').with(:value  => auth_uri)
      should contain_cinder_config('keystone_authtoken/identity_uri').with(:value  => identity_uri)
  end

  it 'ensures cinder_config contains correct values' do
    should contain_cinder_config('DEFAULT/lock_path').with(:value  => '/var/lock/cinder')
  end

  it 'ensures cinder_config contains use_stderr set to false' do
    should contain_cinder_config('DEFAULT/use_stderr').with(:value  => 'false')
  end

  it "should contain cinder config with privileged user settings" do
    should contain_cinder_config('DEFAULT/os_privileged_user_password').with_value(cinder_user_password)
    should contain_cinder_config('DEFAULT/os_privileged_user_tenant').with_value(cinder_tenant)
    should contain_cinder_config('DEFAULT/os_privileged_user_auth_url').with_value("http://#{keystone_auth_host}:5000/")
    should contain_cinder_config('DEFAULT/os_privileged_user_name').with_value(cinder_user)
    should contain_cinder_config('DEFAULT/nova_catalog_admin_info').with_value('compute:nova:adminURL')
    should contain_cinder_config('DEFAULT/nova_catalog_info').with_value('compute:nova:internalURL')
  end

  sahara  = Noop.hiera_structure 'sahara_hash/enabled'
  storage = Noop.hiera_hash 'storage_hash'
  if (sahara and storage['volumes_lvm']) or storage['volumes_block_device']
    filters = [ 'InstanceLocalityFilter', 'AvailabilityZoneFilter', 'CapacityFilter', 'CapabilitiesFilter' ]
  else
    filters = [ 'AvailabilityZoneFilter', 'CapacityFilter', 'CapabilitiesFilter' ]
  end

  it 'configures cinder scheduler filters' do
    should contain_class('cinder::scheduler::filter').with( :scheduler_default_filters => filters )
  end

  it 'should configure keystone_authtoken memcached_servers' do
    should contain_cinder_config('keystone_authtoken/memcached_servers').with_value(memcached_servers.join(','))
  end

  end # end of shared_examples

 test_ubuntu_and_centos manifest

end
