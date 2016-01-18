#
# == Class: openstack::ceilometer
#
# Installs and configures Ceilometer
#
# [use_stderr] Rather or not service should send output to stderr. Optional. Defaults to true.
#
# [*db_connection*]
#   Connection string to use for ceilometer
#   Defaults to 'mysql://ceilometer:ceilometer_pass@localhost/ceilometer'
#

class openstack::ceilometer (
  $keystone_password          = 'ceilometer_pass',
  $keystone_user              = 'ceilometer',
  $keystone_tenant            = 'services',
  $keystone_region            = 'RegionOne',
  $metering_secret            = 'ceilometer',
  $verbose                    =  false,
  $use_syslog                 =  false,
  $use_stderr                 =  true,
  $syslog_log_facility        = 'LOG_LOCAL0',
  $default_log_levels         = undef,
  $db_connection              = 'mysql://ceilometer:ceilometer_pass@localhost/ceilometer',
  $debug                      = false,
  $swift_rados_backend        = false,
  $mongo_replicaset           = undef,
  $amqp_hosts                 = '127.0.0.1',
  $amqp_user                  = 'guest',
  $amqp_password              = 'rabbit_pw',
  $rabbit_ha_queues           = false,
  $keystone_protocol          = 'http',
  $keystone_host              = '127.0.0.1',
  $host                       = '0.0.0.0',
  $port                       = '8777',
  $primary_controller         = false,
  $on_controller              = false,
  $on_compute                 = false,
  $ha_mode                    = false,
  # ttl is 1 week (3600*24*7)
  $os_endpoint_type           = 'internalURL',
  $alarm_history_time_to_live = '604800',
  $event_time_to_live         = '604800',
  $metering_time_to_live      = '604800',
  $http_timeout               = '600',
  $api_workers                = '1',
  $collector_workers          = '1',
  $notification_workers       = '1',
) {

  # Add the base ceilometer class & parameters
  # This class is required by ceilometer agents & api classes
  # The metering_secret parameter is mandatory
  class { '::ceilometer':
    http_timeout               => $http_timeout,
    event_time_to_live         => $event_time_to_live,
    metering_time_to_live      => $metering_time_to_live,
    alarm_history_time_to_live => $alarm_history_time_to_live,
    package_ensure             => 'present',
    rabbit_hosts               => split($amqp_hosts, ','),
    rabbit_userid              => $amqp_user,
    rabbit_password            => $amqp_password,
    metering_secret            => $metering_secret,
    verbose                    => $verbose,
    debug                      => $debug,
    use_syslog                 => $use_syslog,
    use_stderr                 => $use_stderr,
    log_facility               => $syslog_log_facility,
  }

  # TODO (iberezovskiy): Move to globals (as it is done for sahara)
  # after new sync with upstream because of
  # https://github.com/openstack/puppet-ceilometer/blob/master/manifests/init.pp#L160
  class { '::ceilometer::logging':
    default_log_levels => $default_log_levels,
  }

  # Configure authentication for agents
  class { '::ceilometer::agent::auth':
    auth_url         => "${keystone_protocol}://${keystone_host}:5000/v2.0",
    auth_password    => $keystone_password,
    auth_region      => $keystone_region,
    auth_tenant_name => $keystone_tenant,
    auth_user        => $keystone_user,
  }

  class { '::ceilometer::client': }

  if ($on_controller) {
    # Configure the ceilometer database
    if $mongo_replicaset {
      ceilometer_config {
        'database/mongodb_replica_set' : value => $mongo_replicaset;
      }
    } else {
      ceilometer_config {
        'database/mongodb_replica_set' : ensure => absent;
      }
    }

    ceilometer_config { 'service_credentials/os_endpoint_type': value => $os_endpoint_type} ->
    Service<| title == 'ceilometer-agent-central'|>

    class { '::ceilometer::db':
      database_connection => $db_connection,
      sync_db             => $primary_controller,
    }

    # Install the ceilometer-api service
    # The keystone_password parameter is mandatory
    class { '::ceilometer::api':
      keystone_protocol    => $keystone_protocol,
      keystone_host        => $keystone_host,
      keystone_user        => $keystone_user,
      keystone_password    => $keystone_password,
      keystone_tenant      => $keystone_tenant,
      host                 => $host,
      port                 => $port,
      api_workers          => $api_workers,
    }

    # Clean up expired data once a week
    class { '::ceilometer::expirer':
      minute       => '0',
      hour         => '0',
      monthday     => '*',
      month        => '*',
      weekday      => '0',
    }

    class { '::ceilometer::collector':
      collector_workers => $collector_workers,
    }

    class { '::ceilometer::agent::central': }

    class { '::ceilometer::alarm::evaluator':
      evaluation_interval => 60,
    }

    class { '::ceilometer::alarm::notifier': }

    class { '::ceilometer::agent::notification':
      notification_workers => $notification_workers,
      store_events         => true,
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
      'DEFAULT/swift_rados_backend' : value => true;
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
    if $::operatingsystem == 'Ubuntu' and $::ceilometer::params::libvirt_group {
      # Our libvirt-bin deb package (1.2.9 version) creates 'libvirt' group on Ubuntu
      if (versioncmp($::libvirt_package_version, '1.2.9') >= 0) {
        User<| name == 'ceilometer' |> {
          groups => ['nova', 'libvirt'],
        }
      }
    }
    # Install compute agent
    class { 'ceilometer::agent::compute':
      enabled => true,
    }
    ceilometer_config { 'service_credentials/os_endpoint_type': value => $os_endpoint_type} ->
    Service<| title == 'ceilometer-agent-compute'|>
  }
}
