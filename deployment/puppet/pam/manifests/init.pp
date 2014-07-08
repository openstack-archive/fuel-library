# == Class: pam
#
# Puppet module to manage pam configuration
# FIXME: not sure if I'll give it any usage to this class
#
# === Parameters
#
#  []
#    **Required**
#
#  [enable_motd]
#    Use motd to report the usage of this module.
#    *Requires*: https://github.com/torian/puppet-motd.git
#    *Optional* (defaults to false)
#
#  [ensure]
#    *Optional* (defaults to 'present')
#
#
# == Tested/Works on:
#   - Debian: 5.0   / 6.0   / 7.0
#   - Redhat: 5.x   / 6.x   /
#   - CentOS: 5.x   / 6.x   /
#
#
# === Examples
#
# class { 'pam':
#
#
# }
#
#
# === Authors
#
# Emiliano Castagnari ecastag@gmail.com (a.k.a. Torian)
#
#
# === Copyleft
#
# Copyleft (C) 2012 Emiliano Castagnari ecastag@gmail.com (a.k.a. Torian)
#
#
class pam(
  $enable_motd = false,
  $ensure      = present) {

  notify { "***** pam_module:*****": }
  include pam::params

  package { $pam::params::packages:
    ensure => $ensure
  }

  file { $pam::params::prefix_pamd:
    ensure => present,
    owner  => $pam::params::owner,
    group  => $pam::params::group,
    mode   => '0755',
  }

}
