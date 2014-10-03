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
  $enable_secauth     = 'UNSET',
  $authkey_source     = 'file',
  $authkey            = '/etc/puppet/ssl/certs/ca.pem',
  $threads            = 'UNSET',
  $port               = 'UNSET',
  $bind_address       = 'UNSET',
  $multicast_address  = 'UNSET',
  $unicast_addresses  = 'UNSET',
  $force_online       = false,
  $check_standby      = false,
  $debug              = false,
  $rrp_mode           = 'none',
  $ttl                = false,
  $packages           = ['corosync', 'pacemaker'],
) {

  # Making it possible to provide data with parameterized class declarations or
  # Console.
  $threads_real = $threads ? {
    'UNSET' => $::threads ? {
      undef   => $::processorcount,
      default => $::threads,
    },
    default => $threads,
  }

  $port_real = $port ? {
    'UNSET' => $::port ? {
      undef   => '5405',
      default => $::port,
    },
    default => $port,
  }

  $bind_address_real = $bind_address ? {
    'UNSET' => $::bind_address ? {
      undef   => $::ipaddress,
      default => $::bind_address,
    },
    default => $bind_address,
  }

  $unicast_addresses_real = $unicast_addresses ? {
    'UNSET' => $::unicast_addresses ? {
      undef   => 'UNSET',
      default => $::unicast_addresses
    },
    default => $unicast_addresses
  }
  if $unicast_addresses_real == 'UNSET' {
    $corosync_conf = "${module_name}/corosync.conf.erb"
  } else {
    $corosync_conf = "${module_name}/corosync.conf.udpu.erb"
  }

  # We use an if here instead of a selector since we need to fail the catalog if
  # this value is provided.  This is emulating a required variable as defined in
  # parameterized class.

  # $multicast_address is NOT required if $unicast_address is provided
  if $multicast_address == 'UNSET' and $unicast_addresses_real == 'UNSET' {
    if ! $::multicast_address {
      fail('You must provide a value for multicast_address')
    } else {
      $multicast_address_real = $::multicast_address
    }
  } else {
    $multicast_address_real = $multicast_address
  }

  if $enable_secauth == 'UNSET' {
    case $::enable_secauth {
      true:  { $enable_secauth_real = 'on' }
      false: { $enable_secauth_real = 'off' }
      undef:   { $enable_secauth_real = 'on' }
      '':      { $enable_secauth_real = 'on' }
      default: { validate_re($::enable_secauth, '^true$|^false$') }
    }
  } else {
      case $enable_secauth {
        true:   { $enable_secauth_real = 'on' }
        false:  { $enable_secauth_real = 'off' }
        default: { fail('The enable_secauth class parameter requires a true or false boolean') }
      }
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
      default: {
        fail("authkey_source must be either 'file' or 'string'.")
      }
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
    'RedHat': {
      exec { 'enable corosync':
        require => Package['corosync'],
        before  => Service['corosync'],
      }
    }
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

  if $check_standby == true {
    # Throws a puppet error if node is on standby
    exec { 'check_standby node':
      command => 'echo "Node appears to be on standby" && false',
      path    => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
      onlyif  => "crm node status|grep ${::hostname}-standby|grep 'value=\"on\"'",
      require => Service['corosync'],
    }
  }

  if $force_online == true {
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
