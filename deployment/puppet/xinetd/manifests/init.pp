# Class: xinetd
#
# This module manages xinetd
#
# Sample Usage:
#   xinetd::service { 'rsync':
#     port        => '873',
#     server      => '/usr/bin/rsync',
#     server_args => '--daemon --config /etc/rsync.conf',
#  }
#
class xinetd (
  $confdir            = $xinetd::params::confdir,
  $conffile           = $xinetd::params::conffile,
  $package_name       = $xinetd::params::package_name,
  $service_name       = $xinetd::params::service_name,
  $service_restart    = $xinetd::params::service_restart,
  $service_status     = $xinetd::params::service_status,
  $service_hasrestart = $xinetd::params::service_hasrestart,
  $service_hasstatus  = $xinetd::params::service_hasstatus,
) inherits xinetd::params {

  File {
    owner   => 'root',
    group   => '0',
    notify  => Service[$service_name],
    require => Package[$package_name],
  }

  file { $confdir:
    ensure  => directory,
    mode    => '0755',
  }

  # Template uses:
  #   $confdir
  file { $conffile:
    ensure  => file,
    mode    => '0644',
    content => template('xinetd/xinetd.conf.erb'),
  }

  package { $package_name:
    ensure => installed,
    before => Service[$service_name],
  }

  service { $service_name:
    ensure     => running,
    enable     => true,
    hasrestart => $service_hasrestart,
    hasstatus  => $service_hasstatus,
    restart    => $service_restart,
    status     => $service_status,
    require    => File[$conffile],
  }
}
