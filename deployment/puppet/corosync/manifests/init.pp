# == Class: corosync
#
# This class will set up corosync for use by the Puppet Enterprise console to
# facilitate an active/standby configuration for high availability.  It is
# assumed that this module has been initially ran on a Puppet master with the
# capabilities of signing certificates to do the initial key generation.
#
# === Parameters
#
# [*enable_secauth*]
#   Controls corosync's ability to authenticate and encrypt multicast messages.
#
# [*authkey_source*]
#   Allows to use either a file or a string as a authkey.
#   Defaults to 'file'. Can be set to 'string'.
#
# [*authkey*]
#   Specifies the path to the CA which is used to sign Corosync's certificate if
#   authkey_source is 'file' or the actual authkey if 'string' is used instead.
#
# [*threads*]
#   How many threads you are going to let corosync use to encode and decode
#   multicast messages.  If you turn off secauth then corosync wil ignore
#   threads.
#
# [*bind_address*]
#   The ip address we are going to bind the corosync daemon too.
#   Can be specified as an array to have multiple rings (multicast only).
#
# [*port*]
#   The udp port that corosync will use to do its multicast communication.  Be
#   aware that corosync used this defined port plus minus one.
#   Can be specified as an array to have multiple rings (multicast only).
#
# [*multicast_address*]
#   An IP address that has been reserved for multicast traffic.  This is the
#   default way that Corosync accomplishes communication across the cluster.
#   Use 'broadcast' to have broadcast instead
#   Can be specified as an array to have multiple rings (multicast only).
#
# [*unicast_addresses*]
#   An array of IP addresses that make up the cluster's members.  These are
#   use if you are able to use multicast on your network and instead opt for
#   the udpu transport.  You need a relatively recent version of Corosync to
#   make this possible.
#
# [*force_online*]
#   True/false parameter specifying whether to force nodes that have been put
#   in standby back online.
#
# [*check_standby*]
#   True/false parameter specifying whether puppet should return an error log
#   message if a node is in standby. Useful for monitoring node state.
#
# [*debug*]
#   True/false parameter specifying whether Corosync should produce debug
#   output in its logs.
#
# [*rrp_mode*]
#   Mode of redundant ring. May be none, active, or passive.
#
# [*ttl*]
#   Time To Live (multicast only).
#
# [*packages*]
#   Define the list of software packages which should be installed.
#
# === Examples
#
#  class { 'corosync':
#    enable_secauth    => false,
#    bind_address      => '192.168.2.10',
#    multicast_address => '239.1.1.2',
#  }
#
# === Authors
#
# Cody Herriges <cody@puppetlabs.com>
#
# === Copyright
#
# Copyright 2012, Puppet Labs, LLC.
#
class corosync(
  $enable_secauth    = $::corosync::params::enable_secauth,
  $authkey_source    = $::corosync::params::authkey_source,
  $authkey           = $::corosync::params::authkey,
  $threads           = $::corosync::params::threads,
  $port              = $::corosync::params::port,
  $bind_address      = $::corosync::params::bind_address,
  $multicast_address = $::corosync::params::multicast_address,
  $unicast_addresses = $::corosync::params::unicast_addresses,
  $force_online      = $::corosync::params::force_online,
  $check_standby     = $::corosync::params::check_standby,
  $debug             = $::corosync::params::debug,
  $rrp_mode          = $::corosync::params::rrp_mode,
  $ttl               = $::corosync::params::ttl,
  $packages          = $::corosync::params::packages,
) inherits ::corosync::params {

  if ! is_bool($enable_secauth) {
    validate_re($enable_secauth, '^(on|off)$')
  }
  validate_re($authkey_source, '^(file|string)$')
  validate_bool($force_online)
  validate_bool($check_standby)
  validate_bool($debug)

  if $unicast_addresses == 'UNSET' {
    $corosync_conf = "${module_name}/corosync.conf.erb"
  } else {
    $corosync_conf = "${module_name}/corosync.conf.udpu.erb"
  }

  # $multicast_address is NOT required if $unicast_address is provided
  if $multicast_address == 'UNSET' and $unicast_addresses == 'UNSET' {
      fail('You must provide a value for multicast_address')
  }

  case $enable_secauth {
    true:    { $enable_secauth_real = 'on' }
    false:   { $enable_secauth_real = 'off' }
    default: { $enable_secauth_real = $enable_secauth }
  }

  # Using the Puppet infrastructure's ca as the authkey, this means any node in
  # Puppet can join the cluster.  Totally not ideal, going to come up with
  # something better.
  if $enable_secauth_real == 'on' {
    case $authkey_source {
      'file': {
        file { '/etc/corosync/authkey':
          ensure  => file,
          source  => $authkey,
          mode    => '0400',
          owner   => 'root',
          group   => 'root',
          notify  => Service['corosync'],
          require => Package['corosync'],
        }
      }
      'string': {
        file { '/etc/corosync/authkey':
          ensure  => file,
          content => $authkey,
          mode    => '0400',
          owner   => 'root',
          group   => 'root',
          notify  => Service['corosync'],
          require => Package['corosync'],
        }
      }
      default: {}
    }
  }

  package {$packages:
    ensure => present,
  }

  # Template uses:
  # - $unicast_addresses
  # - $multicast_address
  # - $debug
  # - $bind_address_real
  # - $port_real
  # - $enable_secauth_real
  # - $threads_real
  file { '/etc/corosync/corosync.conf':
    ensure  => file,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template($corosync_conf),
    require => Package['corosync'],
  }

  file { '/etc/corosync/service.d':
    ensure  => directory,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    recurse => true,
    purge   => true,
    require => Package['corosync']
  }

  case $::osfamily {
    'Debian': {
      exec { 'enable corosync':
        command => 'sed -i s/START=no/START=yes/ /etc/default/corosync',
        path    => [ '/bin', '/usr/bin' ],
        unless  => 'grep START=yes /etc/default/corosync',
        require => Package['corosync'],
        before  => Service['corosync'],
      }
    }
    default: {}
  }

  if $check_standby {
    # Throws a puppet error if node is on standby
    exec { 'check_standby node':
      command => 'echo "Node appears to be on standby" && false',
      path    => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
      onlyif  => "crm node status|grep ${::hostname}-standby|grep 'value=\"on\"'",
      require => Service['corosync'],
    }
  }

  if $force_online {
    exec { 'force_online node':
      command => 'crm node online',
      path    => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
      onlyif  => "crm node status|grep ${::hostname}-standby|grep 'value=\"on\"'",
      require => Service['corosync'],
    }
  }

  service { 'corosync':
    ensure    => running,
    enable    => true,
    subscribe => File[ [ '/etc/corosync/corosync.conf', '/etc/corosync/service.d' ] ],
  }
}
