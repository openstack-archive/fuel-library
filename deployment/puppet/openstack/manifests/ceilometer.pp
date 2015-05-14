#
# == Class: openstack::ceilometer
#
# Installs and configures Ceilometer
#

class openstack::ceilometer (
  $keystone_password   = 'ceilometer_pass',
  $metering_secret     = 'ceilometer',
  $verbose             =  false,
  $use_syslog          =  false,
  $syslog_log_facility = 'LOG_LOCAL0',
  $debug               =  false,
  $db_type             = 'mysql',
  $db_host             = 'localhost',
  $db_user             = 'ceilometer',
  $db_password         = 'ceilometer_pass',
  $db_dbname           = 'ceilometer',
  $swift_rados_backend = false,
  $mongo_replicaset    = undef,
  $amqp_hosts          = '127.0.0.1',
  $amqp_user           = 'guest',
  $amqp_password       = 'rabbit_pw',
  $rabbit_ha_queues    = false,
  $keystone_host       = '127.0.0.1',
  $host                = '0.0.0.0',
  $port                = '8777',
  $on_controller       = false,
  $on_compute          = false,
  $ha_mode             = false,
  $ext_mongo           = false,
  # ttl is 1 week (3600*24*7)
  $time_to_live        = '604800',
) {

  # Add the base ceilometer class & parameters
  # This class is required by ceilometer agents & api classes
  # The metering_secret parameter is mandatory
  class { '::ceilometer':
    package_ensure      => 'present',
    rabbit_hosts        => split($amqp_hosts, ','),
    rabbit_userid       => $amqp_user,
    rabbit_password     => $amqp_password,
    metering_secret     => $metering_secret,
    verbose             => $verbose,
    debug               => $debug,
    use_syslog          => $use_syslog,
    log_facility        => $syslog_log_facility,
  }

  # Configure authentication for agents
  class { '::ceilometer::agent::auth':
    auth_url      => "http://${keystone_host}:5000/v2.0",
    auth_password => $keystone_password,
  }

  class { '::ceilometer::client': }

  if ($on_controller) {
    # Configure the ceilometer database
    # Only needed if ceilometer::agent::central or ceilometer::api are declared

    if ( !$ext_mongo ) {
      if ( $db_type == 'mysql' ) {
        $current_database_connection = "${db_type}://${db_user}:${db_password}@${db_host}/${db_dbname}?read_timeout=60"
      } else {
        if ( !$mongo_replicaset ) {
          $current_database_connection = "${db_type}://${db_user}:${db_password}@${db_host}/${db_dbname}"
        } else {
          $current_database_connection = "${db_type}://${db_user}:${db_password}@${db_host}/${db_dbname}"
          ceilometer_config {
            'database/mongodb_replica_set' : value => $mongo_replicaset;
          }
        }
      }
    } else {
       $current_database_connection = "${db_type}://${db_user}:${db_password}@${db_host}/${db_dbname}"
       if $mongo_replicaset {
         ceilometer_config {
            'database/mongodb_replica_set' : value => $mongo_replicaset;
          }
       }
    }

    class { '::ceilometer::db':
      database_connection => $current_database_connection,
    }

    # Install the ceilometer-api service
    # The keystone_password parameter is mandatory
    class { '::ceilometer::api':
      keystone_host     => $keystone_host,
      keystone_password => $keystone_password,
      host              => $host,
      port              => $port,
    }

    # Clean up expired data once a week
    class { '::ceilometer::expirer':
      time_to_live => $time_to_live,
      minute       => '0',
      hour         => '0',
      monthday     => '*',
      month        => '*',
      weekday      => '0',
    }

    class { '::ceilometer::collector': }

    class { '::ceilometer::agent::central': }

    class { '::ceilometer::alarm::evaluator':
      evaluation_interval => 60,
    }

    class { '::ceilometer::alarm::notifier': }

    class { '::ceilometer::agent::notification':
      store_events => true,
    }

    if $ha_mode {
      include ceilometer_ha::agent::central

      Package[$::ceilometer::params::common_package_name] -> Class['::ceilometer_ha::agent::central']
      Package[$::ceilometer::params::agent_central_package_name] -> Class['::ceilometer_ha::agent::central']
    }
    else {
      Package[$::ceilometer::params::common_package_name] -> Service[$::ceilometer::params::agent_central_service_name]
      Package[$::ceilometer::params::agent_central_package_name] -> Service[$::ceilometer::params::agent_central_service_name]
    }
  }

  if $ha_mode {
    include ceilometer_ha::alarm::evaluator

    case $::osfamily {
      'RedHat': {
        $alarm_package = $::ceilometer::params::alarm_package_name[0]
      }
      'Debian': {
        $alarm_package = $::ceilometer::params::alarm_package_name[1]
      }
    }

    Package[$::ceilometer::params::common_package_name] -> Class['ceilometer_ha::alarm::evaluator']
    Package[$alarm_package] -> Class['ceilometer_ha::alarm::evaluator']
  }

  if ($swift_rados_backend) {
    ceilometer_config {
       'DEFAULT/swift_rados_backend'    : value => $swift_rados_backend;
    }
  }

  if ($use_syslog) {
    ceilometer_config {
       'DEFAULT/use_syslog_rfc_format': value => true;
    }
  }

  Package<| title == $::ceilometer::params::alarm_package or
    title == 'ceilometer-common'|> ~>
  Service<| title == 'ceilometer-alarm-evaluator'|>

  if !defined(Service['ceilometer-alarm-evaluator']) {
    notify{ "Module ${module_name} cannot notify service ceilometer-alarm-evaluator on packages update": }
  }

  if ($on_compute) {
    # Install compute agent
    class { 'ceilometer::agent::compute':
      enabled => true,
    }
    ceilometer_config { 'service_credentials/os_endpoint_type': value => 'internalURL'} ->
    Service<| title == 'ceilometer-agent-compute'|>
  }
}
