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
  $mongo_replicaset    = false,
  $queue_provider      = 'rabbitmq',
  $amqp_hosts          = '127.0.0.1',
  $amqp_user           = 'guest',
  $amqp_password       = 'rabbit_pw',
  $rabbit_ha_queues    = false,
  $keystone_host       = '127.0.0.1',
  $bind_host           = '0.0.0.0',
  $bind_port           = '8777',
  $on_controller       = false,
  $on_compute          = false,
  $ha_mode             = false,
  $primary_controller  = false,
  $use_neutron         = false,
  $swift               = false,
) {

  # Add the base ceilometer class & parameters
  # This class is required by ceilometer agents & api classes
  # The metering_secret parameter is mandatory
  class { '::ceilometer':
    package_ensure      => $::openstack_version['ceilometer'],
    queue_provider      => $queue_provider,
    amqp_hosts          => $amqp_hosts,
    amqp_user           => $amqp_user,
    amqp_password       => $amqp_password,
    rabbit_ha_queues    => $rabbit_ha_queues,
    metering_secret     => $metering_secret,
    verbose             => $verbose,
    debug               => $debug,
    use_syslog          => $use_syslog,
    syslog_log_facility => $syslog_log_facility,
  }

  class { '::ceilometer::client': }

  if ($on_controller) {
    # Configure the ceilometer database
    # Only needed if ceilometer::agent::central or ceilometer::api are declared

        if ( $db_type == 'mysql' ) {
          $current_database_connection = "${db_type}://${db_user}:${db_password}@${db_host}/${db_dbname}?read_timeout=60"
        } else {
          if ( !$mongo_replicaset ) {
            $current_database_connection = "${db_type}://${db_user}:${db_password}@${db_host}/${db_dbname}"
          } else {
            # added for future use with replicaset params
            $current_database_connection = "${db_type}://${db_user}:${db_password}@${db_host}/${db_dbname}"
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
      bind_host         => $bind_host,
      bind_port         => $bind_port,
    }

    class { '::ceilometer::collector': }

    class { '::ceilometer::agent::central':
      auth_host          => $keystone_host,
      auth_password      => $keystone_password,
      ha_mode            => $ha_mode,
      primary_controller => $primary_controller
    }

    class { '::ceilometer::alarm::evaluator':
      eval_interval      => 600,
      ha_mode            => $ha_mode,
      primary_controller => $primary_controller
    }

    class { '::ceilometer::alarm::notifier': }

    class { '::ceilometer::agent_notification':
      use_neutron => $use_neutron,
      swift       => $swift,
    }
 }

  if ($on_compute) {
    # Install compute agent
    class { 'ceilometer::agent::compute':
      auth_host     => $keystone_host,
      auth_password => $keystone_password,
    }
  }
}
