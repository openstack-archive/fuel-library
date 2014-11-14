# == Class: osnailyfacter::atop
#
# Allow to install and configure atop.
#
# === Parameters
#
# [*service_enabled*]
#   Enable atop service, default to true.
#
# [*service_state*]
#   Start atop service, default to running.
#
# [*interval*]
#   Interval between snapshots, default to 600.
#
# [*logpath*]
#   Directory were the log will be saved by the service.
#   Default is /var/log/atop.
class osnailyfacter::atop (
  $service_enabled = true,
  $service_state   = 'running',
  $interval        = '600',
  $logpath         = '/var/log/atop',
  ) {
  $conf_file = $osfamily ? {
    'Debian' => '/etc/default/atop',
    'RedHat' => '/etc/sysconfig/atop',
    default  => fail('Unsupported Operating System.'),
  }

  package { 'atop':
    ensure => 'installed',
  } ->

  file { $conf_file:
    ensure  => present,
    content => template('osnailyfacter/atop.erb'),
  } ~>

  service { 'atop':
    ensure => $service_state,
    enable => $service_enabled,
  }
}
