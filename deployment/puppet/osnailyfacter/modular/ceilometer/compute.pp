notice('MODULAR: ceilometer/compute.pp')

$verbose                  = hiera('verbose', true)
$debug                    = hiera('debug', false)
$use_syslog               = hiera('use_syslog', true)
$syslog_log_facility      = hiera('syslog_log_facility_ceilometer', 'LOG_LOCAL0')
$amqp_hosts               = hiera('amqp_hosts')
$rabbit_hash              = hiera('rabbit_hash')
$management_vip           = hiera('management_vip')

$default_ceilometer_hash = {
  'enabled'         => false,
  'db_password'     => 'ceilometer',
  'user_password'   => 'ceilometer',
  'metering_secret' => 'ceilometer',
}

$ceilometer_hash          = hiera('ceilometer', $default_ceilometer_hash)

$ceilometer_enabled         = $ceilometer_hash['enabled']
$amqp_password              = $rabbit_hash['password']
$amqp_user                  = $rabbit_hash['user']
$service_endpoint           = $management_vip
$ceilometer_user_password   = $ceilometer_hash['user_password']
$ceilometer_metering_secret = $ceilometer_hash['metering_secret']

if ($ceilometer_enabled) {
  class { 'openstack::ceilometer':
    verbose                        => $verbose,
    debug                          => $debug,
    use_syslog                     => $use_syslog,
    syslog_log_facility            => $syslog_log_facility,
    amqp_hosts                     => $amqp_hosts,
    amqp_user                      => $amqp_user,
    amqp_password                  => $amqp_password,
    keystone_host                  => $service_endpoint,
    keystone_password              => $ceilometer_user_password,
    on_compute                     => true,
    metering_secret                => $ceilometer_metering_secret,
  }

  # We need to restart nova-compute service in orderto apply new settings
  include ::nova::params
  service { 'nova-compute':
    ensure => 'running',
    name   => $::nova::params::compute_service_name,
  }
}
