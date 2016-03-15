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
    bind_address       = Noop.puppet_function 'get_network_role_property', 'ceilometer/api', 'ipaddr'

    region                 = Noop.hiera 'region', 'RegionOne'
    ceilometer_region      = Noop.puppet_function 'pick',ceilometer_hash['region'], region
    management_vip         = Noop.hiera 'management_vip'
    service_endpoint       = Noop.hiera 'service_endpoint', management_vip
    ssl_hash               = Noop.hiera_structure('use_ssl', {})
    internal_auth_protocol = Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','protocol','http'
    internal_auth_endpoint = Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','hostname',[service_endpoint]
    keystone_identity_uri  = "#{internal_auth_protocol}://#{internal_auth_endpoint}:35357/"
    keystone_auth_uri      = "#{internal_auth_protocol}://#{internal_auth_endpoint}:5000/"

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

      it 'should declare openstack::ceilometer class with correct parameters' do
        should contain_class('openstack::ceilometer').with(
          'amqp_user'             => rabbit_user,
          'amqp_password'         => rabbit_password,
          'on_controller'         => 'true',
          'use_stderr'            => 'false',
          'primary_controller'    => primary_controller,
          'keystone_auth_uri'     => keystone_auth_uri,
          'keystone_identity_uri' => keystone_identity_uri,
        )
      end

      it 'should configure auth and identity uri' do
        should contain_ceilometer_config('keystone_authtoken/auth_uri').with(:value => keystone_auth_uri)
        should contain_ceilometer_config('keystone_authtoken/identity_uri').with(:value => keystone_identity_uri)
      end

      it 'should configure OS ENDPOINT TYPE for ceilometer' do
        should contain_ceilometer_config('service_credentials/os_endpoint_type').with(:value => 'internalURL')
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

      it 'should declare openstack::ceilometer class with 4 processess on 4 CPU & 32G system' do
        should contain_class('openstack::ceilometer').with(
          'api_workers'          => '4',
          'collector_workers'    => '4',
          'notification_workers' => '4',
        )
      end

      it 'should configure workers for API, Collector and Agent Notification services' do
        fallback_workers = [[facts[:processorcount].to_i, 2].max, workers_max.to_i].min
        service_workers = Noop.puppet_function 'pick', ceilometer_hash['workers'], fallback_workers

        should contain_ceilometer_config('api/workers').with(:value => service_workers)
        should contain_ceilometer_config('collector/workers').with(:value => service_workers)
        should contain_ceilometer_config('notification/workers').with(:value => service_workers)
      end

      it 'should configure auth url' do
        should contain_ceilometer_config('service_credentials/os_auth_url').with(:value => keystone_auth_uri)
      end

    end

  end # end of shared_examples


  if ha_mode
    it { is_expected.to contain_class('ceilometer_ha::agent::central') }
  end

  it 'contains class ceilometer::agent::polling' do
    should contain_class('ceilometer::agent::polling').with(
      'enabled'           => !ha_mode,
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

  it 'configured ceilometer::agent::auth' do
    should contain_class('ceilometer::agent::auth').with(
      'auth_url'         => keystone_auth_uri,
      'auth_password'    => ceilometer_hash['user_password'],
      'auth_region'      => ceilometer_region,
      'auth_tenant_name' => ceilometer_hash['tenant'],
      'auth_user'        => ceilometer_hash['user'],
    )
  end

  it 'configures ceilometer::api'
    should contain_class('ceilometer::api').with(
        'auth_uri'          => keystone_auth_uri,
        'identity_uri'      => keystone_identity_uri,
        'keystone_user'     => ceilometer_hash['user'],
        'keystone_password' => ceilometer_hash['user_password'],
        'keystone_tenant'   => ceilometer_hash['tenant'],
        'host'              => bind_address,
    )
  end

  test_ubuntu_and_centos manifest
end

