class openstack_tasks::ceilometer::controller {

  notice('MODULAR: ceilometer/controller.pp')

  $default_ceilometer_hash = {
    'enabled'                    => false,
    'db_password'                => 'ceilometer',
    'user_password'              => 'ceilometer',
    'metering_secret'            => 'ceilometer',
    'http_timeout'               => '600',
    'event_time_to_live'         => '604800',
    'metering_time_to_live'      => '604800',
  }

  $ceilometer_hash          = hiera_hash('ceilometer', $default_ceilometer_hash)
  $debug                    = pick($ceilometer_hash['debug'], hiera('debug', false))
  $use_syslog               = hiera('use_syslog', true)
  $use_stderr               = hiera('use_stderr', false)
  $syslog_log_facility      = hiera('syslog_log_facility_ceilometer', 'LOG_LOCAL0')
  $storage_hash             = hiera('storage')
  $rabbit_hash              = hiera_hash('rabbit')
  $management_vip           = hiera('management_vip')
  $region                   = hiera('region', 'RegionOne')
  $ceilometer_region        = pick($ceilometer_hash['region'], $region)
  $mongo_nodes              = get_nodes_hash_by_roles(hiera_hash('network_metadata'), hiera('mongo_roles'))
  $mongo_address_map        = get_node_to_ipaddr_map_by_network_role($mongo_nodes, 'mongo/db')
  $primary_controller       = hiera('primary_controller', false)
  $kombu_compression        = hiera('kombu_compression', $::os_service_default)

  $ceilometer_enabled         = $ceilometer_hash['enabled']
  $ceilometer_metering_secret = $ceilometer_hash['metering_secret']
  $swift_rados_backend        = $storage_hash['objects_ceph']
  $transport_url              = hiera('transport_url','rabbit://guest:password@127.0.0.1:5672/')
  $service_endpoint           = hiera('service_endpoint', $management_vip)
  $ha_mode                    = pick($ceilometer_hash['ha_mode'], true)
  $ssl_hash                   = hiera_hash('use_ssl', {})
  $workers_max                = hiera('workers_max', $::os_workers)
  $service_workers            = pick($ceilometer_hash['workers'],
  min(max($::processorcount, 2), $workers_max))

  $internal_auth_protocol     = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
  $internal_auth_endpoint     = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [$service_endpoint])
  $keystone_auth_url          = "${internal_auth_protocol}://${internal_auth_endpoint}:35357/"
  $keystone_auth_uri          = "${internal_auth_protocol}://${internal_auth_endpoint}:5000/"

  $memcached_servers = hiera('memcached_servers')
  $local_memcached_server = hiera('local_memcached_server')
  $database_max_retries = pick($ceilometer_hash['database_max_retries'], '-1')
#as $ssl default value in ceilometer::wsgi::apache is true and
#we use SSL at HAproxy, but not the API host we should set 'false'
#value for $ssl.
  $ssl = false

  prepare_network_config(hiera_hash('network_scheme', {}))
  $api_bind_address           = get_network_role_property('ceilometer/api', 'ipaddr')

  # Database related items
  $default_mongo_hash = {
    'enabled' => false,
  }
  $mongo_hash = hiera_hash('mongo', $default_mongo_hash)
  $db_type    = 'mongodb'

  $rabbit_heartbeat_timeout_threshold = pick($ceilometer_hash['rabbit_heartbeat_timeout_threshold'], $rabbit_hash['heartbeat_timeout_threshold'], 60)
  $rabbit_heartbeat_rate              = pick($ceilometer_hash['rabbit_heartbeat_rate'], $rabbit_hash['rabbit_heartbeat_rate'], 2)

  if $mongo_hash['enabled'] and $ceilometer_hash['enabled'] {
    $external_mongo_hash = hiera_hash('external_mongo')
    $db_user             = $external_mongo_hash['mongo_user']
    $db_password         = $external_mongo_hash['mongo_password']
    $db_name             = $external_mongo_hash['mongo_db_name']
    $db_host             = sort($external_mongo_hash['hosts_ip'])
    if $external_mongo_hash['mongo_replset'] {
      $mongo_replicaset  = $external_mongo_hash['mongo_replset']
    } else {
      $mongo_replicaset  = undef
    }
  } else {
    $db_user             = 'ceilometer'
    $db_password         = $ceilometer_hash['db_password']
    $db_name             = 'ceilometer'
    $db_host             = join(sorted_hosts($mongo_address_map, 'ip', 'ip'), ',')
    # MongoDB is alsways configured with replica set
    $mongo_replicaset    = 'ceilometer'
  }

  # TODO(aschultz): currently mysql is not supported for ceilometer, but this
  # should be configurable some day
  if ($dbtype == 'mysql') {
    # LP#1526938 - python-mysqldb supports this, python-pymysql does not
    if ($::os_package_type == 'debian') {
      $extra_params = { 'charset' =>  'utf8', 'read_timeout' => 60 }
    } else {
      $extra_params = { 'charset' =>  'utf8'}
    }
    $db_connection = os_database_connection({
      'dialect'  => $db_type,
      'host'     => $db_host,
      'database' => $db_name,
      'username' => $db_user,
      'password' => $db_password,
      'extra'    => $extra_params
      })
  } else {
    $mongo_default_params = {
      'readPreference' => 'primaryPreferred',
    }
    if $mongo_replicaset {
      $replica_params = {
        'replicaSet' => $mongo_replicaset
      }
    } else {
      $replica_params = { }
    }
    $extra_params = merge($mongo_default_params, $replica_params)

    $params = inline_template("?<%= @extra_params.map{ |k,v| \"#{k}=#{v}\" }.join('&') %>")
    # NOTE(aschultz): os_database_connection does not currently support the
    # mongodb syntax for mongodb://user:pass@host,host,host/dbname
    $db_connection = "${db_type}://${db_user}:${db_password}@${db_host}/${db_name}${params}"
  }

  #############################################################################

  if ($ceilometer_enabled) {
    class { '::ceilometer':
      http_timeout                       => $ceilometer_hash['http_timeout'],
      event_time_to_live                 => $ceilometer_hash['event_time_to_live'],
      metering_time_to_live              => $ceilometer_hash['metering_time_to_live'],
      metering_secret                    => $ceilometer_metering_secret,
      debug                              => $debug,
      use_syslog                         => $use_syslog,
      use_stderr                         => $use_stderr,
      log_facility                       => $syslog_log_facility,
      default_transport_url              => $transport_url,
      kombu_compression                  => $kombu_compression,
      rabbit_heartbeat_timeout_threshold => $rabbit_heartbeat_timeout_threshold,
      rabbit_heartbeat_rate              => $rabbit_heartbeat_rate,
    }

    # Configure authentication for agents
    class { '::ceilometer::agent::auth':
      auth_url         => $keystone_auth_uri,
      auth_password    => $ceilometer_hash['user_password'],
      auth_region      => $ceilometer_region,
      auth_tenant_name => $ceilometer_hash['tenant'],
      auth_user        => $ceilometer_hash['user'],
    }

    class { '::ceilometer::client': }

    ceilometer_config {
      'database/mongodb_replica_set' : ensure => absent;
    }

    ceilometer_config { 'service_credentials/interface':
      value => 'internalURL'
    } ->
    Service<| title == 'ceilometer-polling'|>

    class { '::ceilometer::db':
      database_connection  => $db_connection,
      sync_db              => $primary_controller,
      database_max_retries => $database_max_retries,
    }

    class { 'osnailyfacter::apache':
      listen_ports => hiera_array('apache_ports', ['0.0.0.0:80', '0.0.0.0:8888', '0.0.0.0:5000', '0.0.0.0:35357', '0.0.0.0:8777']),
    }

    class { 'ceilometer::wsgi::apache':
      ssl       => $ssl,
      bind_host => $api_bind_address,
      workers   => $service_workers,
    }

    class { '::ceilometer::keystone::authtoken':
      username          => $ceilometer_hash['user'],
      password          => $ceilometer_hash['user_password'],
      project_name      => $ceilometer_hash['tenant'],
      auth_url          => $keystone_auth_url,
      auth_uri          => $keystone_auth_uri,
      memcached_servers => $local_memcached_server,
    }

    # Install the ceilometer-api service
    class { '::ceilometer::api':
      host         => $api_bind_address,
      service_name => 'httpd',
      api_workers  => $service_workers,
    }

    # Clean up expired data once a week
    class { '::ceilometer::expirer':
      minute   => '0',
      hour     => '0',
      monthday => '*',
      month    => '*',
      weekday  => '0',
    }

    class { '::ceilometer::collector':
      collector_workers => $service_workers,
    }

    class { '::ceilometer::agent::notification':
      notification_workers => $service_workers,
      store_events         => true,
    }

    if $ha_mode {
      include cluster::ceilometer_central
      Service['ceilometer-polling'] -> Class['::cluster::ceilometer_central']
    }

    class { '::ceilometer::agent::polling':
      enabled           => !$ha_mode,
      compute_namespace => false,
      ipmi_namespace    => false
    }

    if ($swift_rados_backend) {
      ceilometer_config {
        'DEFAULT/swift_rados_backend' : value => true;
      }
    }

    if ($use_syslog) {
      ceilometer_config {
        'DEFAULT/use_syslog_rfc_format': value => true;
      }
    }
  }
}
