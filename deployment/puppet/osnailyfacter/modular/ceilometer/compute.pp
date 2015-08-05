notice('MODULAR: ceilometer/compute.pp')

$verbose                  = hiera('verbose', true)
$debug                    = hiera('debug', false)
$use_syslog               = hiera('use_syslog', true)
$syslog_log_facility      = hiera('syslog_log_facility_ceilometer', 'LOG_LOCAL0')
$rabbit_hash              = hiera_hash('rabbit_hash')
$management_vip           = hiera('management_vip')
$service_endpoint         = hiera('service_endpoint')

$default_ceilometer_hash = {
  'enabled'         => false,
  'db_password'     => 'ceilometer',
  'user_password'   => 'ceilometer',
  'metering_secret' => 'ceilometer',
}

$region                     = hiera('region', 'RegionOne')
$ceilometer_hash            = hiera_hash('ceilometer_hash', $default_ceilometer_hash)
$ceilometer_region          = pick($ceilometer_hash['region'], $region)
$ceilometer_enabled         = $ceilometer_hash['enabled']
$amqp_password              = $rabbit_hash['password']
$amqp_user                  = $rabbit_hash['user']
$ceilometer_user_password   = $ceilometer_hash['user_password']
$ceilometer_metering_secret = $ceilometer_hash['metering_secret']
$event_time_to_live         = pick($ceilometer_hash['event_time_to_live'], '604800')
$metering_time_to_live      = pick($ceilometer_hash['metering_time_to_live'], '604800')
$ceilometer_http_timeout    = pick($ceilometer_hash['http_timeout'], '600')

if ($ceilometer_enabled) {
  class { 'openstack::ceilometer':
    verbose               => $verbose,
    debug                 => $debug,
    use_syslog            => $use_syslog,
    syslog_log_facility   => $syslog_log_facility,
    amqp_hosts            => hiera('amqp_hosts',''),
    amqp_user             => $amqp_user,
    amqp_password         => $amqp_password,
    keystone_user         => $ceilometer_hash['user'],
    keystone_tenant       => $ceilometer_hash['tenant'],
    keystone_region       => $ceilometer_region,
    keystone_host         => $service_endpoint,
    keystone_password     => $ceilometer_user_password,
    on_compute            => true,
    metering_secret       => $ceilometer_metering_secret,
    event_time_to_live    => $event_time_to_live,
    metering_time_to_live => $metering_time_to_live,
    http_timeout          => $ceilometer_http_timeout,
  }

  # We need to restart nova-compute service in orderto apply new settings
  include ::nova::params
  service { 'nova-compute':
    ensure => 'running',
    name   => $::nova::params::compute_service_name,
  }
}
