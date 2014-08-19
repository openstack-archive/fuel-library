# == Class: fail2ban
#
# Module for fail2ban configuration.
#
# === Parameters
#
# [*jails*]
#   List of jails to activate. Currently supported options are imap, pop3, ssh, vsftpd
#
# [*mailto*]
#   The mail address where to send notifications
#
# === Examples
#
#  class { fail2ban:
#    jails  => ['ssh'],
#    mailto => 'root@example.com',
#  }
#
# === Authors
#
# Alessandro De Salvo <Alessandro.DeSalvo@roma1.infn.it>
#
# === Copyright
#
# Copyright 2014 Alessandro De Salvo
#
class fail2ban (
  $jails = [],
  $mailto = undef
) inherits params {
    file { $fail2ban::params::config_file:
        owner   => root,
        group   => root,
        mode    => 644,
        content => template('fail2ban/fail2ban.local.erb'),
        require => Package[$fail2ban::params::package],
        notify  => Service[$fail2ban::params::service]
    }
    file { $fail2ban::params::jail_file:
        owner   => root,
        group   => root,
        mode    => 644,
        content => template('fail2ban/jail.local.erb'),
        require => Package[$fail2ban::params::package],
        notify  => Service[$fail2ban::params::service]
    }
    package { $fail2ban::params::package: ensure => latest }
    service { $fail2ban::params::service:
        ensure => running,
        enable => true,
        hasrestart => true,
        require => Package[$fail2ban::params::package]
    }
}
