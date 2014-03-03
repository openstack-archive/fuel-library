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
  $debug               =  false,
  $db_type             = 'mysql',
  $db_host             = 'localhost',
  $db_user             = 'ceilometer',
  $db_password         = 'ceilometer_pass',
  $db_dbname           = 'ceilometer',
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
) {

  # Add the base ceilometer class & parameters
  # This class is required by ceilometer agents & api classes
  # The metering_secret parameter is mandatory
  class { '::ceilometer':
    package_ensure   => $::openstack_version['ceilometer'],
    queue_provider   => $queue_provider,
    amqp_hosts       => $amqp_hosts,
    amqp_user        => $amqp_user,
    amqp_password    => $amqp_password,
    rabbit_ha_queues => $rabbit_ha_queues,
    metering_secret  => $metering_secret,
    verbose          => $verbose,
    debug            => $debug,
    use_syslog       => $use_syslog,
  }

  class { '::ceilometer::client': }

  if ($on_controller) {
    # Configure the ceilometer database
    # Only needed if ceilometer::agent::central or ceilometer::api are declared
    class { '::ceilometer::db':
      database_connection => "${db_type}://${db_user}:${db_password}@${db_host}/${db_dbname}",
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
      auth_host     => $keystone_host,
      auth_password => $keystone_password,
      ha_mode       => $ha_mode,
    }

    class { '::ceilometer::alarm::evaluator':
      eval_interval => 600,
      ha_mode       => $ha_mode,
    }

    class { '::ceilometer::alarm::notifier': }
  }

  if ($on_compute) {
    # Install compute agent
    class { 'ceilometer::agent::compute':
      auth_host     => $keystone_host,
      auth_password => $keystone_password,
    }
  }
}
