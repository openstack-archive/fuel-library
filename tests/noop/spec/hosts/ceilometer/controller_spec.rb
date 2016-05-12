# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'ceilometer/controller.pp'

describe manifest do
  shared_examples 'catalog' do

    # TODO All this stuff should be moved to shared examples controller* tests.
    workers_max = Noop.hiera 'workers_max'
    rabbit_user = Noop.hiera_structure 'rabbit/user', 'nova'
    rabbit_password = Noop.hiera_structure 'rabbit/password'
    ceilometer_hash = Noop.hiera_structure 'ceilometer'
    ceilometer_user_password = ceilometer_hash['user_password']
    ceilometer_tenant = Noop.hiera_structure('ceilometer/tenant', "services")
    ceilometer_user = Noop.hiera_structure('ceilometer/user', "ceilometer")
    mongo_hash = Noop.hiera_structure('mongo', { 'enabled' => false })
    network_metadata = Noop.hiera_structure 'network_metadata'
    mongo_roles = Noop.hiera 'mongo_roles'
    mongo_nodes = Noop.puppet_function 'get_nodes_hash_by_roles',network_metadata,mongo_roles
    mongo_address_map = Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role',mongo_nodes,'mongo/db'
    if mongo_hash['enabled'] and ceilometer_hash['enabled']
      external_mongo_hash    = Noop.hiera_structure 'external_mongo'
      ceilometer_db_user     = external_mongo_hash['mongo_user']
      ceilometer_db_password = external_mongo_hash['mongo_password']
      ceilometer_db_dbname   = external_mongo_hash['mongo_db_name']
      db_hosts               = external_mongo_hash['hosts_ip']
      mongo_replicaset       = external_mongo_hash['mongo_replset']
    else
      ceilometer_db_user     = 'ceilometer'
      ceilometer_db_password = ceilometer_hash['db_password']
      ceilometer_db_dbname   = 'ceilometer'
      addresses              = Noop.puppet_function 'values',mongo_address_map
      db_hosts               = Noop.puppet_function 'join',addresses,','
      mongo_replicaset       = 'ceilometer'
    end
    default_log_levels_hash = Noop.hiera_structure 'default_log_levels'
    default_log_levels = Noop.puppet_function 'join_keys_to_values',default_log_levels_hash,'='
    primary_controller = Noop.hiera 'primary_controller'
    ha_mode            = Noop.puppet_function 'pick', ceilometer_hash['ha_mode'], true

    let(:bind_address) { Noop.puppet_function 'get_network_role_property', 'ceilometer/api', 'ipaddr' }

    region                 = Noop.hiera 'region', 'RegionOne'
    ceilometer_region      = Noop.puppet_function 'pick',ceilometer_hash['region'], region
    management_vip         = Noop.hiera 'management_vip'
    service_endpoint       = Noop.hiera 'service_endpoint', management_vip
    ssl_hash               = Noop.hiera_structure('use_ssl', {})
    internal_auth_protocol = Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','protocol','http'
    internal_auth_endpoint = Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','hostname',[service_endpoint]
    keystone_identity_uri  = "#{internal_auth_protocol}://#{internal_auth_endpoint}:35357/"
    keystone_auth_uri      = "#{internal_auth_protocol}://#{internal_auth_endpoint}:5000/"
    kombu_compression      = Noop.hiera 'kombu_compression', ''

    ssl = 'false'

    let (:api_bind_address) do
      api_bind_address = Noop.puppet_function('get_network_role_property', 'ceilometer/api', 'ipaddr')
    end

    let (:service_workers) do
      fallback_workers = [[facts[:processorcount].to_i, 2].max, workers_max.to_i].min
      service_workers = Noop.puppet_function 'pick', ceilometer_hash['workers'], fallback_workers
    end

    # Ceilometer
    if ceilometer_hash['enabled']
      it 'should properly build connection string' do
        if mongo_replicaset and mongo_replicaset != ''
          db_params = "?readPreference=primaryPreferred&replicaSet=#{mongo_replicaset}"
        else
          db_params = "?readPreference=primaryPreferred"
        end
        should contain_ceilometer_config('database/connection').with(:value => "mongodb://#{ceilometer_db_user}:#{ceilometer_db_password}@#{db_hosts}/#{ceilometer_db_dbname}#{db_params}")
      end

      it 'should declare ceilometer::wsgi::apache class with correct parameters' do
        should contain_class('ceilometer::wsgi::apache').with(
          'ssl'       => ssl,
          'bind_host' => api_bind_address,
          'workers'   => service_workers,
        )
      end

      it 'should declare ceilometer::api class with correct parameters' do
        should contain_class('ceilometer::api').with(
          'auth_uri'              => keystone_auth_uri,
          'identity_uri'          => keystone_identity_uri,
          'keystone_user'         => ceilometer_user,
          'keystone_password'     => ceilometer_user_password,
          'keystone_tenant'       => ceilometer_tenant,
          'host'                  => api_bind_address,
          'service_name'          => 'httpd',
        )
      end

      it 'should configure auth and identity uri' do
        should contain_ceilometer_config('keystone_authtoken/auth_uri').with(:value => keystone_auth_uri)
        should contain_ceilometer_config('keystone_authtoken/identity_uri').with(:value => keystone_identity_uri)
      end

      it 'should configure interface (ex. OS ENDPOINT TYPE) for ceilometer' do
        should contain_ceilometer_config('service_credentials/interface').with(:value => 'internalURL')
      end
      event_ttl = ceilometer_hash['event_time_to_live'] ? (ceilometer_hash['event_time_to_live']) : ('604800')
      metering_ttl = ceilometer_hash['metering_time_to_live'] ? (ceilometer_hash['metering_time_to_live']) : ('604800')
      http_timeout = ceilometer_hash['http_timeout'] ? (ceilometer_hash['http_timeout']) : ('600')
      it 'should configure time to live for events and meters' do
        should contain_ceilometer_config('database/event_time_to_live').with(:value => event_ttl)
        should contain_ceilometer_config('database/metering_time_to_live').with(:value => metering_ttl)
      end
      it 'should configure timeout for HTTP requests' do
        should contain_ceilometer_config('DEFAULT/http_timeout').with(:value => http_timeout)
      end

      it 'should configure default log levels' do
        should contain_ceilometer_config('DEFAULT/default_log_levels').with_value(default_log_levels.sort.join(','))
      end

      it 'should configure workers with 4 processess on 4 CPU & 32G system' do
        should contain_class('ceilometer::api').with(
          'api_workers'          => '4'
        )
        should contain_class('ceilometer::collector').with(
          'collector_workers'    => '4'
        )
        should contain_class('ceilometer::agent::notification').with(
          'notification_workers' => '4',
        )
      end

      it 'should configure workers for API, Collector and Agent Notification services' do
        should contain_ceilometer_config('collector/workers').with(:value => service_workers)
        should contain_ceilometer_config('notification/workers').with(:value => service_workers)
      end

      it 'should configure auth url' do
        should contain_ceilometer_config('service_credentials/auth_url').with(:value => keystone_auth_uri)
      end
      ha_mode = Noop.puppet_function 'pick', ceilometer_hash['ha_mode'], 'true'
      if ha_mode
        it { is_expected.to contain_class('cluster::ceilometer_central') }
      end

      it 'contains class ceilometer::agent::polling' do
        should contain_class('ceilometer::agent::polling').with(
          'enabled'           =>  !ha_mode,
          'compute_namespace' => 'false',
          'ipmi_namespace'    => 'false'
        )
      end

      it "configures ceilometer contoller parts" do
        should contain_class('ceilometer')
        should contain_class('ceilometer::logging')
        should contain_class('ceilometer::db')
        should contain_class('ceilometer::expirer')
        should contain_class('ceilometer::agent::notification')
        should contain_class('ceilometer::collector')
        should contain_class('ceilometer::client')
      end

      auth_user = Noop.puppet_function, 'pick', ceilometer_hash['user'], 'ceilometer'
      auth_tenant_name = Noop.puppet_function, 'pick', ceilometer_hash['auth_tenant_name'], 'ceilometer'

      it 'configured ceilometer::agent::auth' do
        should contain_class('ceilometer::agent::auth').with(
          'auth_url'         => keystone_auth_uri,
          'auth_password'    => ceilometer_hash['user_password'],
          'auth_region'      => ceilometer_region,
          'auth_tenant_name' => auth_tenant_name,
          'auth_user'        => auth_user,
        )
      end

      it 'configures ceilometer::api' do
        should contain_class('ceilometer::api').with(
            'auth_uri'          => keystone_auth_uri,
            'identity_uri'      => keystone_identity_uri,
            'keystone_user'     => ceilometer_hash['user'],
            'keystone_password' => ceilometer_hash['user_password'],
            'keystone_tenant'   => ceilometer_hash['tenant'],
            'host'              => bind_address,
        )
      end

      it 'should properly configure rabbit queue' do
        should contain_ceilometer_config('DEFAULT/rpc_backend').with(:value => 'rabbit')
        should contain_ceilometer_config('oslo_messaging_rabbit/rabbit_virtual_host').with(:value => '/')
        should contain_ceilometer_config('oslo_messaging_rabbit/rabbit_use_ssl').with(:value => 'false')
      end

      it 'should configure kombu compression' do
        kombu_compression = Noop.hiera 'kombu_compression', facts[:os_service_default]
        should contain_ceilometer_config('oslo_messaging_rabbit/kombu_compression').with(:value => kombu_compression)
      end
    end # end of ceilometer enabled
  end # end of shared_examples

  test_ubuntu_and_centos manifest
end

