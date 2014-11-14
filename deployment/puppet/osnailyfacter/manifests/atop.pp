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
#
# [*rotate*]
#   How many days keep binary logs.
#   Default is 7.
class osnailyfacter::atop (
  $service_enabled = true,
  $service_state   = 'running',
  $interval        = '10',
  $logpath         = '/var/log/atop',
  $rotate          = '7',
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

  cron { 'atop_cleanup':
    command => "/bin/bash -c '[[ -f ${conf_file} ]] && . ${conf_file} && [[ -d \$LOGPATH ]] && /usr/bin/find \$LOGPATH -type f -mtime +\${KEEPLOGS:-7} -delete' > /dev/null 2>&1",
    user    => root,
    hour    => '15',
    minute  => '4',
  }

### We dont need this cronjob, as it is not configurable
  file { '/etc/cron.d/atop':
    ensure  => absent,
    require => Package['atop'],
  }
}

