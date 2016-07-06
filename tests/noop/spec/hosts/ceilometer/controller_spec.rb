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
    rabbit_ha_queues = 'true'
    default_log_levels_hash = Noop.hiera_structure 'default_log_levels'
    default_log_levels = Noop.puppet_function 'join_keys_to_values',default_log_levels_hash,'='
    primary_controller = Noop.hiera 'primary_controller'

    let(:memcached_servers) { Noop.hiera 'memcached_servers' }

    # Ceilometer
    if ceilometer_hash['enabled']
      it 'should configure connection string with read reference set to primaryPreferred' do
        should contain_ceilometer_config('database/connection').with(:value => "mongodb://#{ceilometer_db_user}:#{ceilometer_db_password}@#{db_hosts}/#{ceilometer_db_dbname}?readpreference=primaryPreferred")
      end

      if mongo_replicaset and mongo_replicaset != ''
        it 'should configure mongo replica set in ceilometer configuration file' do
          should contain_ceilometer_config('database/mongodb_replica_set').with(:value => mongo_replicaset)
        end
      end

      it 'should declare openstack::ceilometer class with correct parameters' do
        should contain_class('openstack::ceilometer').with(
          'amqp_user'          => rabbit_user,
          'amqp_password'      => rabbit_password,
          'rabbit_ha_queues'   => rabbit_ha_queues,
          'on_controller'      => 'true',
          'use_stderr'         => 'false',
          'primary_controller' => primary_controller,
        )
      end
      it 'should configure memcache for keystone_authtoken' do
        should contain_ceilometer_config('keystone_authtoken/memcached_servers').with_value(memcached_servers.join(','))
      end
      it 'should configure OS ENDPOINT TYPE for ceilometer' do
        should contain_ceilometer_config('service_credentials/os_endpoint_type').with(:value => 'internalURL')
      end
      alarm_ttl = ceilometer_hash['alarm_history_time_to_live'] ? (ceilometer_hash['alarm_history_time_to_live']) : ('604800')
      event_ttl = ceilometer_hash['event_time_to_live'] ? (ceilometer_hash['event_time_to_live']) : ('604800')
      metering_ttl = ceilometer_hash['metering_time_to_live'] ? (ceilometer_hash['metering_time_to_live']) : ('604800')
      http_timeout = ceilometer_hash['http_timeout'] ? (ceilometer_hash['http_timeout']) : ('600')
      it 'should configure time to live for alarm history, events and meters' do
        should contain_ceilometer_config('database/alarm_history_time_to_live').with(:value => alarm_ttl)
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

        should contain_ceilometer_config('DEFAULT/api_workers').with(:value => service_workers)
        should contain_ceilometer_config('DEFAULT/collector_workers').with(:value => service_workers)
        should contain_ceilometer_config('DEFAULT/notification_workers').with(:value => service_workers)
      end
    end

  end # end of shared_examples

  test_ubuntu_and_centos manifest
end

