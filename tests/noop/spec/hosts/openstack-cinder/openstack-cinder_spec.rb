# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-cinder/openstack-cinder.pp'

describe manifest do

  before(:each) do
    Noop.puppet_function_load :is_pkg_installed
    MockFunction.new(:is_pkg_installed) do |function|
      allow(function).to receive(:call).and_return false
    end
  end

  shared_examples 'catalog' do

  max_pool_size = 20
  max_retries = '-1'
  max_overflow = 20
  cinder_hash = Noop.hiera_structure 'cinder'
  ceilometer_hash = Noop.hiera_structure 'ceilometer'
  workers_max = Noop.hiera 'workers_max'
  rabbit_ha_queues = Noop.hiera('rabbit_ha_queues')
  cinder_user = Noop.hiera_structure('cinder/user', "cinder")
  cinder_user_password = Noop.hiera_structure('cinder/user_password')
  cinder_tenant = Noop.hiera_structure('cinder/tenant', "services")
  default_log_levels_hash = Noop.hiera_hash 'default_log_levels'
  default_log_levels = Noop.puppet_function 'join_keys_to_values',default_log_levels_hash,'='
  primary_controller = Noop.hiera 'primary_controller'
  volume_backend_name = Noop.hiera_structure 'storage/volume_backend_names'
  kombu_compression = Noop.hiera 'kombu_compression', ''

  database_vip = Noop.hiera('database_vip')
  cinder = Noop.puppet_function 'roles_include', 'cinder'
  cinder_db_password = Noop.hiera_structure 'cinder/db_password', 'cinder'
  cinder_db_user = Noop.hiera_structure 'cinder/db_user', 'cinder'
  cinder_db_name = Noop.hiera_structure 'cinder/db_name', 'cinder'

  use_ceph = Noop.hiera_structure('storage/images_ceph')
  ubuntu_tgt_service_name = 'tgt'
  ubuntu_tgt_package_name = 'tgt'

  sahara  = Noop.hiera_structure 'sahara/enabled'
  storage = Noop.hiera_hash 'storage'

  let(:manage_volumes) do
    if cinder and storage['volumes_lvm']
      'iscsi'
    elsif storage['volumes_ceph']
      'ceph'
    else
      false
    end
  end

  it 'should configure default_log_levels' do
    should contain_cinder_config('DEFAULT/default_log_levels').with_value(default_log_levels.sort.join(','))
  end

  it 'should configure the database connection string' do
    if facts[:os_package_type] == 'debian'
      extra_params = '?charset=utf8&read_timeout=60'
    else
      extra_params = '?charset=utf8'
    end
    should contain_class('cinder').with(
      :database_connection => "mysql://#{cinder_db_user}:#{cinder_db_password}@#{database_vip}/#{cinder_db_name}#{extra_params}"
    )
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

  it 'should declare ::cinder class with cinder_* parameters' do
    should contain_class('cinder').with(
      :report_interval   => cinder_hash['cinder_report_interval'],
      :service_down_time => cinder_hash['cinder_service_down_time'],
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

  it 'should configure workers for API service' do
    fallback_workers = [[facts[:processorcount].to_i, 2].max, workers_max.to_i].min
    service_workers = cinder_hash.fetch('workers', fallback_workers)
    should contain_cinder_config('DEFAULT/osapi_volume_workers').with(:value => service_workers)
    should contain_class('cinder::api').with('service_workers' => service_workers,)
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

    should contain_cinder_config('oslo_concurrency/lock_path').with(:value  => lock_path)
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


  it 'ensures tgt is installed and stopped om Ubuntu with ceph' do
    if facts[:operatingsystem] == 'Ubuntu' and use_ceph
      should contain_package(ubuntu_tgt_package_name).that_comes_before('Class[cinder::volume]')
      should contain_service(ubuntu_tgt_service_name).with(
        'enable' => 'false',
        'ensure' => 'stopped',
      )
    end
  end


  it 'adds tweaks for cinder-backup' do
    if manage_volumes
      should contain_tweaks__ubuntu_service_override('cinder-backup')
    else
      should_not contain_tweaks__ubuntu_service_override('cinder-backup')
    end
  end

  if (sahara and storage['volumes_lvm']) or storage['volumes_block_device']
    filters = [ 'InstanceLocalityFilter', 'AvailabilityZoneFilter', 'CapacityFilter', 'CapabilitiesFilter' ]
  else
    filters = [ 'AvailabilityZoneFilter', 'CapacityFilter', 'CapabilitiesFilter' ]
  end

  it 'configures cinder scheduler filters' do
    should contain_class('cinder::scheduler::filter').with( :scheduler_default_filters => filters )
  end

  it 'ensures that cinder have proper volume_backend_name' do
    if cinder and storage['volumes_lvm']
      should contain_cinder__backend__iscsi('DEFAULT').with(
        'volume_backend_name' => volume_backend_name['volumes_lvm']
      )
    elsif storage['volumes_ceph']
      should contain_cinder__backend__rbd('DEFAULT').with(
       'volume_backend_name' => volume_backend_name['volumes_ceph']
      )
    else
      should_not contain_cinder_config('DEFAULT/volume_backend_name')
    end
  end

  it 'should contain notification_driver option' do
    if ceilometer_hash['enabled']
      should contain_cinder_config('DEFAULT/notification_driver').with(:value => ceilometer_hash['notification_driver'])
    else
      should_not contain_cinder_config('DEFAULT/notification_driver')
    end
  end

    let (:bind_host) do
      Noop.puppet_function('get_network_role_property', 'cinder/api', 'ipaddr')
    end

  it { is_expected.to contain_class('cinder::api').with(
    'bind_host'                  => bind_host,
    'identity_uri'               => identity_uri,
    'keymgr_encryption_auth_url' => "#{identity_uri}/v3",
  ) }

  it { is_expected.to contain_class('cinder') }
  it { is_expected.to contain_class('cinder::glance') }
  it { is_expected.to contain_class('cinder::logging') }
  it { is_expected.to contain_class('cinder::scheduler') }
  it {
    if manage_volumes
      is_expected.to contain_class('cinder::volume')
    else
      is_expected.to_not contain_class('cinder::volume')
    end
  }

  if ['gzip', 'bz2'].include?(kombu_compression)
    it 'should configure kombu compression' do
      should contain_cinder_config('oslo_messaging_rabbit/kombu_compression').with(:value => kombu_compression)
    end
  end

  end # end of shared_examples

 test_ubuntu_and_centos manifest

end
