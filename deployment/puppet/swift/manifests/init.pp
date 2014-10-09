# Install and configure base swift components
#
# == Parameters
# [*swift_hash_suffix*] string of text to be used
#   as a salt when hashing to determine mappings in the ring.
#   This file should be the same on every node in the cluster.
#
# [*package_ensure*] The ensure state for the swift package.
#   (Optional) Defaults to present.
#
# [*client_package_ensure*] The ensure state for the swift client package.
#   (Optional) Defaults to present.
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
  $package_ensure        = 'present',
  $client_package_ensure = 'present',
) {

  include swift::params
  include ssh::server::install

  Class['ssh::server::install'] -> Class['swift']

  if !defined(Package['swift']) {
    package { 'swift':
      ensure => $package_ensure,
      name   => $::swift::params::package_name,
    }
  }

  class { 'swift::client':
    ensure => $client_package_ensure;
  }

  File { owner => 'swift', group => 'swift', require => Package['swift'] }

  file { '/home/swift':
    ensure  => directory,
    mode    => '0700',
  }

  file { '/etc/swift':
    ensure => directory,
    mode   => '2770',
  }
  user {'swift':
    ensure => present,
  }
  file { '/var/lib/swift':
    ensure => directory,
  }
  file { '/var/run/swift':
    ensure => directory,
  }

  file { '/etc/swift/swift.conf':
    ensure  => present,
    mode    => '0660',
  }

  swift_config { 'swift-hash/swift_hash_path_suffix':
    value => $swift_hash_suffix
  }
}
