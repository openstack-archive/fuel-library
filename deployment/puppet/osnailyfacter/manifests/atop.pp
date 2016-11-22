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
#
# [*custom_acct_file*]
#   Location of the custom accounting file. (e.g. '/tmp/atop.d/atop.acct')
#   Set 'undef' to disable accounting, 'false' to use atop default settings.
#   Default is undef.
#
class osnailyfacter::atop (
  $service_enabled  = true,
  $service_state    = $service_enabled ? { false => 'stopped', default => 'running' },
  $interval         = '20',
  $logpath          = '/var/log/atop',
  $rotate           = '7',
  $custom_acct_file = undef,
) {

  case $::osfamily {
    'Debian': {
      $conf_file    = '/etc/default/atop'
      $acct_package = 'acct'
    }
    'RedHat': {
      $conf_file    = '/etc/sysconfig/atop'
      $acct_package = 'psacct'
    }
    default: {
      fail("Unsupported platform: ${::osfamily}/${::operatingsystem}")
    }
  }

  $atop_retention = '/etc/cron.daily/atop_retention'
  $atop_retention_ensure = $service_enabled ? { false => 'absent', default => 'file' }

  File {
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0600'
  }

  if $custom_acct_file {
    validate_absolute_path($custom_acct_file)
    $acct_file_dir = dirname($custom_acct_file)

    # Manage the parent directory
    file { $acct_file_dir:
      ensure => directory,
    } ->

    file { $custom_acct_file:
    } ~>

    exec { 'turns process accounting on':
      path        => ['/sbin', '/usr/sbin'],
      command     => "accton ${custom_acct_file}",
      refreshonly => true,
    }

    Package[$acct_package] -> Exec['turns process accounting on'] -> Service['atop']
  }

  # pick packages to install
  $atop_packages = $custom_acct_file ? {
    undef   => 'atop',
    default => ['atop', $acct_package],
  }

  package { $atop_packages:
    ensure => 'installed',
  } ->

  # Template uses:
  # - $interval
  # - $logpath
  # - $custom_acct_file
  file { $conf_file:
    mode    => '0644',
    content => template('osnailyfacter/atop.erb'),
  } ~>

  service { 'atop':
    ensure => $service_state,
    enable => $service_enabled,
  } ->

  # This file is used for atop binary log rotations by (ana)cron
  # Template uses:
  # - $rotate
  # - $logpath
  file { $atop_retention:
    ensure  => $atop_retention_ensure,
    mode    => '0755',
    content => template('osnailyfacter/atop_retention.erb'),
  }

  if $service_enabled {
    exec { 'initialize atop_current':
      command     => $atop_retention,
      refreshonly => true,
      subscribe   => File[$atop_retention],
    }
  }

}
