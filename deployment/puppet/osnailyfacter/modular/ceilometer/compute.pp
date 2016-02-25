notice('MODULAR: ceilometer/compute.pp')

$use_syslog               = hiera('use_syslog', true)
$use_stderr               = hiera('use_stderr', false)
$syslog_log_facility      = hiera('syslog_log_facility_ceilometer', 'LOG_LOCAL0')
$rabbit_hash              = hiera_hash('rabbit_hash')
$management_vip           = hiera('management_vip')
$service_endpoint         = hiera('service_endpoint', $management_vip)

$default_ceilometer_hash = {
  'enabled'                    => false,
  'db_password'                => 'ceilometer',
  'user_password'              => 'ceilometer',
  'metering_secret'            => 'ceilometer',
  'http_timeout'               => '600',
  'event_time_to_live'         => '604800',
  'metering_time_to_live'      => '604800',
  'alarm_history_time_to_live' => '604800',
}

$region                     = hiera('region', 'RegionOne')
$ceilometer_hash            = hiera_hash('ceilometer_hash', $default_ceilometer_hash)
$ceilometer_region          = pick($ceilometer_hash['region'], $region)
$ceilometer_enabled         = $ceilometer_hash['enabled']
$verbose                    = pick($ceilometer_hash['verbose'], hiera('verbose', true))
$debug                      = pick($ceilometer_hash['debug'], hiera('debug', false))
$ssl_hash                   = hiera_hash('use_ssl', {})



if ($ceilometer_enabled) {

  # Add the base ceilometer class & parameters
  # This class is required by ceilometer agents & api classes
  # The metering_secret parameter is mandatory
  class { '::ceilometer':
    http_timeout               => $ceilometer_hash['http_timeout'],
    event_time_to_live         => $ceilometer_hash['event_time_to_live'],
    metering_time_to_live      => $ceilometer_hash['metering_time_to_live'],
    alarm_history_time_to_live => $ceilometer_hash['alarm_history_time_to_live'],
    package_ensure             => 'present',
    rabbit_hosts               => split($hiera('amqp_hosts',''), ','),
    rabbit_userid              => $rabbit_hash['user'],
    rabbit_password            => $rabbit_hash['password'],
    metering_secret            => $ceilometer_hash['metering_secret'],
    verbose                    => $verbose,
    debug                      => $debug,
    use_syslog                 => $use_syslog,
    use_stderr                 => $use_stderr,
    log_facility               => $syslog_log_facility,
  }

  # Configure authentication for agents
  class { '::ceilometer::agent::auth':
    auth_url         => "${keystone_protocol}://${keystone_host}:5000/v2.0",
    auth_password    => $ceilometer_hash['user_password'],
    auth_region      => $ceilometer_region,
    auth_tenant_name => $ceilometer_hash['tenant'],
    auth_user        => $ceilometer_hash['user'],
  }

  class { '::ceilometer::client': }

  if ($use_syslog) {
    ceilometer_config {
      'DEFAULT/use_syslog_rfc_format': value => true;
    }
  }

  Package<| title == $::ceilometer::params::alarm_package or
    title == 'ceilometer-common'|> ~>
  Service<| title == 'ceilometer-alarm-evaluator'|>

  # Install polling agent
  class { '::ceilometer::agent::polling':
    central_namespace => false,
    ipmi_namespace    => false
  }

  ceilometer_config { 'service_credentials/os_endpoint_type': value => 'internalURL'} ->
  Service<| title == 'ceilometer-polling'|>
}
