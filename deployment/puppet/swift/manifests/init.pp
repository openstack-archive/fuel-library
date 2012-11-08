# Install and configure base swift components
#
# == Parameters
# [*swift_hash_suffix*] string of text to be used
# as a salt when hashing to determine mappings in the ring.
# This file should be the same on every node in the cluster.
# [*package_ensure*] The ensure state for the swift package.
#   Optional. Defaults to present.
#
# == Dependencies
#
#   Class['ssh::server::install']
#
# == Authors
#
#   Dan Bode dan@puppetlabs.com
#
# == Copyright
#
# Copyright 2011 Puppetlabs Inc, unless otherwise noted.
#
class swift(
  $swift_hash_suffix,
  $package_ensure = 'present'
) {

  include swift::params

  Class['ssh::server::install'] -> Class['swift']

  package { 'swift':
    name   => $::swift::params::package_name,
    ensure => $package_ensure,
  }

  File { owner => 'swift', group => 'swift', require => Package['swift'] }

  file { '/home/swift':
    ensure  => directory,
    mode    => 0700,
  }

  file { '/etc/swift':
    ensure => directory,
    mode   => 2770,
  }

  file { '/var/run/swift':
    ensure => directory,
  }

  file { '/etc/swift/swift.conf':
    ensure  => present,
    mode    => 0660,
    content => template('swift/swift.conf.erb'),
  }
}
