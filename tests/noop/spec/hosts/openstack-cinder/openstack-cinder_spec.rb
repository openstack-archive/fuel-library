require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-cinder/openstack-cinder.pp'

describe manifest do
  shared_examples 'catalog' do

  max_pool_size = 20
  max_retries = '-1'
  max_overflow = 20
  cinder_hash = Noop.hiera_structure 'cinder'
  workers_max = Noop.hiera 'workers_max'
  rabbit_ha_queues = Noop.hiera('rabbit_ha_queues')
  cinder_user = Noop.hiera_structure('cinder/user', "cinder")
  cinder_user_password = Noop.hiera_structure('cinder/user_password')
  cinder_tenant = Noop.hiera_structure('cinder/tenant', "services")
  default_log_levels_hash = Noop.hiera_hash 'default_log_levels'
  default_log_levels = Noop.puppet_function 'join_keys_to_values',default_log_levels_hash,'='
  primary_controller = Noop.hiera 'primary_controller'
  volume_backend_name = Noop.hiera_structure 'storage_hash/volume_backend_names'
  cinder = Noop.puppet_function 'roles_include', 'cinder'
  let(:memcached_servers) { Noop.hiera 'memcached_servers' }

  it 'should configure default_log_levels' do
    should contain_cinder_config('DEFAULT/default_log_levels').with_value(default_log_levels.sort.join(','))
  end

  it 'ensures cinder_config contains "oslo_messaging_rabbit/rabbit_ha_queues" ' do
    should contain_cinder_config('oslo_messaging_rabbit/rabbit_ha_queues').with(
      'value' => rabbit_ha_queues,
    )
  end

  it 'should run db_sync only on primary controller' do
    should contain_class('cinder::api').with(
      'sync_db' => primary_controller,
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
  auth_uri            = "#{internal_auth_protocol}://#{keystone_auth_host}:5000/"
  identity_uri        = "#{internal_auth_protocol}://#{keystone_auth_host}:5000/"
  privileged_auth_uri = "#{internal_auth_protocol}://#{keystone_auth_host}:5000/v2.0/"

  it 'should declare cinder::api class with 4 processess on 4 CPU & 32G system' do
    should contain_class('cinder::api').with(
      'service_workers' => '4',
    )
  end

  it 'should configure workers for API service' do
    fallback_workers = [[facts[:processorcount].to_i, 2].max, workers_max.to_i].min
    service_workers = cinder_hash.fetch('workers', fallback_workers)
    should contain_cinder_config('DEFAULT/osapi_volume_workers').with(:value => service_workers)
  end

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
    should contain_cinder_config('DEFAULT/os_privileged_user_auth_url').with_value(privileged_auth_uri)
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

  it 'ensures that cinder have proper volume_backend_name' do
    if use_ceph
      should contain_class('openstack::cinder').with(
        'volume_backend_name' => volume_backend_name['volumes_ceph']
      )
    elsif storage['volumes_lvm']
      if cinder
        should contain_class('openstack::cinder').with(
          'volume_backend_name' => volume_backend_name['volumes_lvm']
        )
      else
        should contain_class('openstack::cinder').with(
          'volume_backend_name' => 'false'
        )
      end
    end
  end

  end # end of shared_examples

 test_ubuntu_and_centos manifest

end
