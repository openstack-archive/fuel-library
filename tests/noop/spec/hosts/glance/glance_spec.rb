# ROLE: primary-controller
# ROLE: controller
# FIXME: neut_vxlan_dvr.murano.sahara-primary-controller ubuntu
# FIXME: neut_vxlan_dvr.murano.sahara-primary-controller ubuntu

require 'spec_helper'
require 'shared-examples'
manifest = 'glance/glance.pp'

describe manifest do

  before(:each) do
    Noop.puppet_function_load :is_pkg_installed
    MockFunction.new(:is_pkg_installed) do |function|
      allow(function).to receive(:call).and_return false
    end
  end

  shared_examples 'catalog' do

    # TODO All this stuff should be moved to shared examples controller* tests.
    workers_max = Noop.hiera 'workers_max'
    glance_config = Noop.hiera_structure 'glance'
    glance_glare_config = Noop.hiera_structure 'glance_glare'
    storage_config = Noop.hiera_structure 'storage'
    max_pool_size = Noop.hiera('max_pool_size')
    max_overflow = Noop.hiera('max_overflow')
    max_retries = '-1'
    use_syslog = Noop.hiera('use_syslog', 'true')
    use_stderr = Noop.hiera('use_stderr', 'false')
    region = Noop.hiera('region', 'RegionOne')
    ironic_enabled = Noop.hiera_structure('ironic/enabled', false)
    default_log_levels_hash = Noop.hiera_hash 'default_log_levels'
    default_log_levels = Noop.puppet_function 'join_keys_to_values',default_log_levels_hash,'='
    primary_controller = Noop.hiera 'primary_controller'
    if glance_config && glance_config.has_key?('pipeline')
       pipeline = glance_config['pipeline']
    else
       pipeline = 'keystone'
    end
    database_vip = Noop.hiera('database_vip')
    glance_db_type = Noop.hiera_structure 'glance/db_type', 'mysql+pymysql'
    glance_db_password = Noop.hiera_structure 'glance/db_password', 'glance'
    glance_db_user = Noop.hiera_structure 'glance/db_user', 'glance'
    glance_db_name = Noop.hiera_structure 'glance/db_name', 'glance'
    glare_db_type = Noop.hiera_structure 'glance_glare/db_type', 'mysql+pymysql'
    glare_db_password = Noop.hiera_structure 'glance_glare/db_password', 'glare'
    glare_db_user = Noop.hiera_structure 'glance_glare/db_user', 'glare'
    glance_db_name = Noop.hiera_structure 'glance_glare/db_name', 'glare'
    glance_password     = glance_config.fetch('user_password')
    glance_username     = glance_config.fetch('user', 'glance')
    glance_project_name = glance_config.fetch('tenant', 'services')

    glance_glare_password     = glance_glare_config.fetch('user_password')
    glance_glare_username     = glance_glare_config.fetch('user', 'glare')
    glance_glare_project_name = glance_glare_config.fetch('tenant', 'services')

    rabbit_hash = Noop.hiera_structure 'rabbit', {}

    let(:ceilometer_hash) { Noop.hiera_structure 'ceilometer' }

    let(:ssl_hash) { Noop.hiera_hash 'use_ssl', {} }

    let(:internal_auth_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','protocol','http' }

    let(:internal_auth_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','hostname',[Noop.hiera('service_endpoint', ''), Noop.hiera('management_vip')] }

    let(:admin_auth_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','admin','protocol','http' }

    let(:admin_auth_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','admin','hostname',[Noop.hiera('service_endpoint', ''), Noop.hiera('management_vip')] }

    let(:auth_uri) { "#{internal_auth_protocol}://#{internal_auth_address}:5000/" }

    let(:auth_url) { "#{admin_auth_protocol}://#{admin_auth_address}:35357/" }

    let(:memcached_servers) { Noop.hiera 'memcached_servers' }
    let(:local_memcached_server) { Noop.hiera 'local_memcached_server' }

    let(:transport_url) { Noop.hiera 'transport_url', 'rabbit://guest:password@127.0.0.1:5672/' }

    rabbit_heartbeat_timeout_threshold = Noop.puppet_function 'pick', glance_config['rabbit_heartbeat_timeout_threshold'], rabbit_hash['heartbeat_timeout_treshold'], 60
    rabbit_heartbeat_rate = Noop.puppet_function 'pick', glance_config['rabbit_heartbeat_rate'], rabbit_hash['heartbeat_rate'], 2

    it 'should contain correct transport url' do
      should contain_class('glance::notify::rabbitmq').with(:default_transport_url => transport_url)
      should contain_glance_api_config('DEFAULT/transport_url').with_value(transport_url)
      should contain_glance_registry_config('DEFAULT/transport_url').with_value(transport_url)
    end

    it 'should configure RabbitMQ Heartbeat parameters' do
      should contain_glance_api_config('oslo_messaging_rabbit/heartbeat_timeout_threshold').with_value(rabbit_heartbeat_timeout_threshold)
      should contain_glance_api_config('oslo_messaging_rabbit/heartbeat_rate').with_value(rabbit_heartbeat_rate)
      should contain_glance_registry_config('oslo_messaging_rabbit/heartbeat_timeout_threshold').with_value(rabbit_heartbeat_timeout_threshold)
      should contain_glance_registry_config('oslo_messaging_rabbit/heartbeat_rate').with_value(rabbit_heartbeat_rate)
    end

    it 'should have correct auth options for Glance API' do
      should contain_class('glance::api::authtoken').with(
        'username'          => glance_username,
        'password'          => glance_password,
        'project_name'      => glance_project_name,
        'auth_url'          => auth_url,
        'auth_uri'          => auth_uri,
        'token_cache_time'  => 300,
        'memcached_servers' => local_memcached_server)
    end

    it 'should have correct auth options for Glare' do
      should contain_class('glare::keystone::authtoken').with(
        'username'          => glance_glare_username,
        'password'          => glance_glare_password,
        'project_name'      => glance_glare_project_name,
        'auth_url'          => auth_url,
        'auth_uri'          => auth_uri,
        'token_cache_time'  => 300,
        'memcached_servers' => local_memcached_server)
    end

    it 'should have correct auth options for Glance Registry' do
      should contain_class('glance::registry::authtoken').with(
        'username'          => glance_username,
        'password'          => glance_password,
        'project_name'      => glance_project_name,
        'auth_url'          => auth_url,
        'auth_uri'          => auth_uri,
        'memcached_servers' => local_memcached_server)
    end

    it 'should configure workers for API, registry services' do
      fallback_workers = [[facts[:processorcount].to_i, 2].max, workers_max.to_i].min
      service_workers = glance_config.fetch('glance_workers', fallback_workers)
      should contain_glance_api_config('DEFAULT/workers').with(:value => service_workers)
      should contain_glance_registry_config('DEFAULT/workers').with(:value => service_workers)
    end

    it 'should declare glance classes' do
      should contain_class('glance::api').with('pipeline' => pipeline)
      should contain_class('glance::registry').with('sync_db' => primary_controller)
      should contain_class('glare').with('pipeline' => pipeline)
      should contain_class('glance::notify::rabbitmq')
    end

    it 'should configure the database connection string' do
        if facts[:os_package_type] == 'debian'
            extra_params = '?charset=utf8&read_timeout=60'
        else
            extra_params = '?charset=utf8'
        end

        glare_db_name = 'glare'

        db_connection = "#{glance_db_type}://#{glance_db_user}:#{glance_db_password}@#{database_vip}/#{glance_db_name}#{extra_params}"
        glare_db_connection = "#{glance_db_type}://#{glance_db_user}:#{glance_db_password}@#{database_vip}/#{glare_db_name}#{extra_params}"
        should contain_class('glance::api').with(:database_connection => db_connection)
        should contain_class('glance::registry').with(:database_connection => db_connection)
        should contain_class('glare::db').with(:database_connection => glare_db_connection)
    end

    it 'should configure glance api config' do
      should contain_glance_api_config('database/max_pool_size').with_value(max_pool_size)
      should contain_glance_api_config('DEFAULT/use_stderr').with_value(use_stderr)
      should contain_glance_api_config('database/max_overflow').with_value(max_overflow)
      should contain_glance_api_config('database/max_retries').with_value(max_retries)
      should contain_glance_api_config('DEFAULT/delayed_delete').with_value(false)
      should contain_glance_api_config('DEFAULT/scrub_time').with_value('43200')
      should contain_glance_api_config('DEFAULT/scrubber_datadir').with_value('/var/lib/glance/scrubber')
      should contain_glance_api_config('glance_store/os_region_name').with_value(region)
      should contain_glance_api_config('keystone_authtoken/auth_type').with_value('password')
      should contain_glance_api_config('keystone_authtoken/auth_url').with_value(auth_url)
      should contain_glance_api_config('keystone_authtoken/auth_uri').with_value(auth_uri)
      should contain_glance_api_config('keystone_authtoken/username').with_value(glance_username)
      should contain_glance_api_config('keystone_authtoken/password').with_value(glance_password)
      should contain_glance_api_config('keystone_authtoken/project_name').with_value(glance_project_name)
      should contain_glance_api_config('keystone_authtoken/token_cache_time').with_value('300')
      should contain_glance_api_config('keystone_authtoken/memcached_servers').with_value(local_memcached_server)
    end

    it 'should configure glare config' do
      should contain_glare_config('database/max_pool_size').with_value(max_pool_size)
      should contain_glare_config('DEFAULT/use_stderr').with_value(use_stderr)
      should contain_glare_config('database/max_overflow').with_value(max_overflow)
      should contain_glare_config('database/max_retries').with_value(max_retries)
      should contain_glare_config('glance_store/os_region_name').with_value(region)
      should contain_glare_config('keystone_authtoken/auth_type').with_value('password')
      should contain_glare_config('keystone_authtoken/auth_url').with_value(auth_url)
      should contain_glare_config('keystone_authtoken/auth_uri').with_value(auth_uri)
      should contain_glare_config('keystone_authtoken/username').with_value(glance_glare_username)
      should contain_glare_config('keystone_authtoken/password').with_value(glance_glare_password)
      should contain_glare_config('keystone_authtoken/project_name').with_value(glance_glare_project_name)
      should contain_glare_config('keystone_authtoken/token_cache_time').with_value('300')
      should contain_glare_config('keystone_authtoken/memcached_servers').with_value(local_memcached_server)
    end

    if $glance_backend == 'rbd'
      it 'should configure rados_connect_timeout' do
        should contain_glance_api_config('glance_store/rados_connect_timeout').with_value('30')
      end
    end

    it 'should configure glance cache config' do
      # LP #1649801 set proper value for use_syslog when https://review.openstack.org/#/c/410467/
      # is merged
      # should contain_glance_cache_config('DEFAULT/use_syslog').with_value(use_syslog)
      # should contain_glance_cache_config('DEFAULT/log_file').with_value('/var/log/glance/cache.log')
      should contain_glance_cache_config('DEFAULT/image_cache_dir').with_value('/var/lib/glance/image-cache/')
      should contain_glance_cache_config('DEFAULT/image_cache_stall_time').with_value('86400')
      should contain_glance_cache_config('DEFAULT/os_region_name').with_value(region)
      should contain_glance_cache_config('glance_store/os_region_name').with_value(region)
      if glance_config && glance_config.has_key?('image_cache_max_size')
        glance_image_cache_max_size = glance_config['image_cache_max_size']
        should contain_glance_cache_config('DEFAULT/image_cache_max_size').with_value(glance_image_cache_max_size)
      end
    end

    it 'should configure glance registry config' do
      should contain_glance_registry_config('DEFAULT/use_stderr').with_value(use_stderr)
      should contain_glance_registry_config('database/max_pool_size').with_value(max_pool_size)
      should contain_glance_registry_config('database/max_overflow').with_value(max_overflow)
      should contain_glance_registry_config('database/max_retries').with_value(max_retries)
      should contain_glance_registry_config('glance_store/os_region_name').with_value(region)
      should contain_glance_registry_config('keystone_authtoken/auth_type').with_value('password')
      should contain_glance_registry_config('keystone_authtoken/auth_url').with_value(auth_url)
      should contain_glance_registry_config('keystone_authtoken/auth_uri').with_value(auth_uri)
      should contain_glance_registry_config('keystone_authtoken/username').with_value(glance_username)
      should contain_glance_registry_config('keystone_authtoken/password').with_value(glance_password)
      should contain_glance_registry_config('keystone_authtoken/project_name').with_value(glance_project_name)
      should contain_glance_registry_config('keystone_authtoken/memcached_servers').with_value(local_memcached_server)
    end

    if use_syslog
      it 'should configure rfc format' do
        should contain_glance_api_config('DEFAULT/use_syslog_rfc_format').with_value('true')
        should contain_glance_cache_config('DEFAULT/use_syslog_rfc_format').with_value('true')
        should contain_glance_registry_config('DEFAULT/use_syslog_rfc_format').with_value('true')
        should contain_glare_config('DEFAULT/use_syslog_rfc_format').with_value('true')
      end
    end

    it 'should configure default_log_levels' do
      should contain_glance_api_config('DEFAULT/default_log_levels').with_value(default_log_levels.sort.join(','))
      should contain_glance_registry_config('DEFAULT/default_log_levels').with_value(default_log_levels.sort.join(','))
      should contain_glare_config('DEFAULT/default_log_levels').with_value(default_log_levels.sort.join(','))
    end

    if storage_config && storage_config.has_key?('images_ceph') && storage_config['images_ceph']
      if glance_config
        if glance_config.has_key?('show_image_direct_url')
          show_image_direct_url = glance_config['show_image_direct_url']
        else
          show_image_direct_url = true
        end
        if glance_config.has_key?('show_multiple_locations')
          show_multiple_locations = glance_config['show_multiple_locations']
        else
          show_multiple_locations = true
        end
      end

      if ironic_enabled
        it 'should declare swift backend' do
          should contain_class('glance::backend::swift').with(:glare_enabled => true)
        end
      end
      let :params do { :glance_backend => 'ceph', } end
      it 'should declare ceph backend' do
        should contain_class('glance::backend::rbd').with(:glare_enabled => true)
      end
      it 'should configure show_image_direct_url' do
        should contain_glance_api_config('DEFAULT/show_image_direct_url').with_value(show_image_direct_url)
      end
      it 'should configure show_multiple_locations' do
        should contain_glance_api_config('DEFAULT/show_multiple_locations').with_value(show_multiple_locations)
      end
    else
      if glance_config
        if glance_config.has_key?('show_image_direct_url')
          show_image_direct_url = glance_config['show_image_direct_url']
        else
          show_image_direct_url = false
        end
        if glance_config.has_key?('show_multiple_locations')
          show_multiple_locations = glance_config['show_multiple_locations']
        else
          show_multiple_locations = false
        end
      end
      let :params do { :glance_backend => 'swift', } end
      it 'should declare swift backend' do
        should contain_class('glance::backend::swift').with(
          'swift_store_region'       => region,
          'swift_store_auth_version' => '3',
          'swift_store_auth_address' => "#{auth_uri}/v3",
        )
      end
      it 'should configure show_image_direct_url' do
        should contain_glance_api_config('DEFAULT/show_image_direct_url').with_value(show_image_direct_url)
      end
      it 'should configure show_multiple_locations' do
        should contain_glance_api_config('DEFAULT/show_multiple_locations').with_value(show_multiple_locations)
      end
    end

    it 'should contain oslo_messaging_notifications "driver" option' do
      should contain_glance_api_config('oslo_messaging_notifications/driver').with(:value => ceilometer_hash['notification_driver'])
      should contain_glance_registry_config('oslo_messaging_notifications/driver').with(:value => ceilometer_hash['notification_driver'])
    end

      it 'should properly configure rabbit queue' do
        should contain_glance_api_config('DEFAULT/rpc_backend').with(:value => 'rabbit')
        should contain_glance_registry_config('DEFAULT/rpc_backend').with(:value => 'rabbit')

        should contain_glance_api_config('oslo_messaging_rabbit/default_notification_exchange').with(:value => 'glance')
        should contain_glance_registry_config('oslo_messaging_rabbit/default_notification_exchange').with(:value => 'glance')
        should contain_glance_api_config('oslo_messaging_notifications/topics').with(:value => 'notifications')
        should contain_glance_registry_config('oslo_messaging_notifications/topics').with(:value => 'notifications')
      end

    it 'should configure kombu compression' do
      kombu_compression = Noop.hiera 'kombu_compression', facts[:os_service_default]
      should contain_glance_api_config('oslo_messaging_rabbit/kombu_compression').with(:value => kombu_compression)
      should contain_glance_registry_config('oslo_messaging_rabbit/kombu_compression').with(:value => kombu_compression)
    end
  end

  test_ubuntu_and_centos manifest
end
