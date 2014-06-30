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
# [*authkey*]
#   Specifies the path to the CA which is used to sign Corosync's certificate.
#
# [*threads*]
#   How many threads you are going to let corosync use to encode and decode
#   multicast messages.  If you turn off secauth then corosync wil ignore
#   threads.
#
# [*bind_address*]
#   The ip address we are going to bind the corosync daemon too.
#
# [*port*]
#   The udp port that corosync will use to do its multcast communication.  Be
#   aware that corosync used this defined port plus minus one.
#
# [*multicast_address*]
#   An IP address that has been reserved for multicast traffic.  This is the
#   default way that Corosync accomplishes communication across the cluster.
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
class corosync (
  $enable_secauth    = 'off',
  $authkey           = '/etc/puppet/ssl/certs/ca.pem',
  $threads           = 0,
  $port              = 5405,
  $bind_address      = $::ipaddress_eth0,
  $multicast_address = "239.1.1.2",
  $unicast_addresses = undef,
  $force_online      = false,
  $check_standby     = false,
  $debug             = false,
) {

  # Making it possible to provide data with parameterized class declarations or
  # Console.

  if $unicast_addresses == undef {
    $corosync_conf = "${module_name}/corosync.conf.erb"
  } else {
    $corosync_conf = "${module_name}/corosync.conf.udpu.erb"
  }

  # We use an if here instead of a selector since we need to fail the catalog if
  # this value is provided.  This is emulating a required variable as defined in
  # parameterized class.

  file { 'limitsconf':
    ensure  => present,
    path    => '/etc/security/limits.conf',
    source => 'puppet:///modules/corosync/limits.conf',
    replace => true,
    owner   => '0',
    group   => '0',
    mode    => '0644',
    before => Service["corosync"],
  }


  # Using the Puppet infrastructure's ca as the authkey, this means any node in
  # Puppet can join the cluster.  Totally not ideal, going to come up with
  # something better.
  if $enable_secauth == 'on' {
    file { '/etc/corosync/authkey':
      ensure => file,
      source => $authkey,
      mode   => '0400',
      owner  => 'root',
      group  => 'root',
      notify => Service['corosync'],
    }
  }
  if $::operatingsystem == 'Ubuntu' {
    file { "/etc/init/corosync.override":
      replace => "no",
      ensure  => "present",
      content => "manual",
      mode    => '0644',
      before  => Package[corosync],
    }
    package {'python-pcs': ensure => present} ->
      Package['pacemaker']
  } else {
    package {'pcs': ensure => present} ->
      package {'crmsh': ensure => present} ->
        Package['pacemaker']
  }
  package { ['corosync', 'pacemaker']: ensure => present }

  # Template uses:
  # - $unicast_addresses
  # - $multicast_address
  # - $debug
  # - $bind_address
  # - $port
  # - $enable_secauth
  # - $threads
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

  if $::osfamily == "RedHat" {
    Package['pacemaker'] ->
    file { '/var/lib/pacemaker':
      ensure  => directory,
      mode    => '0750',
      owner   => 'hacluster',
      group   => 'haclient',
    } ->
    file { '/var/lib/pacemaker/cores':
      ensure  => directory,
      mode    => '0750',
      owner   => 'hacluster',
      group   => 'haclient',
    } ->
    file { '/var/lib/pacemaker/cores/root':
      ensure  => directory,
      mode    => '0750',
      owner   => 'hacluster',
      group   => 'haclient',
    } ->
    Service['corosync']
  }

  if $::osfamily == 'Debian' {
    exec { 'enable corosync':
      command => 'sed -i s/START=no/START=yes/ /etc/default/corosync',
      path    => ['/bin', '/usr/bin'],
      unless  => 'grep START=yes /etc/default/corosync',
      require => Package['corosync'],
      before  => Service['corosync'],
    }
    if $::operatingsystem == 'Ubuntu' {
      exec { 'rm_corosync_override':
        command => '/bin/rm -f /etc/init/corosync.override',
        path    => ['/bin', '/usr/bin'],
      }
    }
  }


  if $check_standby == true {
    # Throws a puppet error if node is on standby
    exec { 'check_standby node':
      command => 'echo "Node appears to be on standby" && false',
      path    => ['/bin', '/usr/bin', '/sbin', '/usr/sbin'],
      onlyif  => "crm node status|grep ${::hostname}-standby|
      grep 'value=\"on\"'",
      require => Service['corosync'],
    }
  }

  if $force_online == true {
    exec { 'force_online node':
      command => 'crm node online',
      path    => ['/bin', '/usr/bin', '/sbin', '/usr/sbin'],
      onlyif  => "crm node status|grep ${::hostname}-standby|
      grep 'value=\"on\"'",
      require => Service['corosync'],
    }
  }

  service { 'corosync':
    ensure    => running,
    enable    => true,
    hasrestart => true,
    hasstatus  => true,
    subscribe => File[['/etc/corosync/corosync.conf', '/etc/corosync/service.d']],
  }

}
