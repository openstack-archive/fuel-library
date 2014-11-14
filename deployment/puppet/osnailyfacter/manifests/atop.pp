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
#   Interval between snapshots, default to 20 seconds.
#
# [*logpath*]
#   Directory were the log will be saved by the service.
#   Default is /var/log/atop.
#
# [*rotate*]
#   How many days keep binary logs.
#   Default is 7.
class osnailyfacter::atop (
  $service_enabled = true,
  $service_state   = 'running',
  $interval        = '20',
  $logpath         = '/var/log/atop',
  $rotate          = '7',
  ) {
  $conf_file = $::osfamily ? {
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
  } ~>

  exec { "ln -s ${logpath}/atop_current":
    command => "ln -s ${logpath}/atop_$(date +%Y%m%d) ${logpath}/atop_current",
    path    => ['/bin', '/usr/bin'],
    unless  => "test -L ${logpath}/atop_current",
    require => Service['atop'];
  }

  # This file is used for atop binary log rotations by (ana)cron
  file { '/etc/logrotate.d/atop':
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('osnailyfacter/atop_logrotate.conf.erb'),
  }
}
