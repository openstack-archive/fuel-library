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
  $swift_hash_suffix = undef,
  $package_ensure = 'present',
) {

  include swift::params

  if !defined(Class['ssh::server::install']) {
    class{ 'ssh::server::install': }
  }

    Class['ssh::server::install'] -> Class['swift']

      class {'rsync::server':}

  if !defined(Package['swift']) {
    package { 'swift':
      ensure => $package_ensure,
      name   => $::swift::params::package_name,
    }
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

  user {'swift': ensure => present}

  file { '/var/lib/swift':
      ensure => directory,
      owner  => 'swift',
    }

  file {'/var/cache/swift':
    ensure => directory
  }

  file { '/var/run/swift':
    ensure => directory,
  }

  file { '/etc/swift/swift.conf':
    ensure  => present,
    mode    => '0660',
    content => template('swift/swift.conf.erb'),
  }

#  file { "/tmp/swift-utils.patch":
#    ensure => present,
#    source => 'puppet:///modules/swift/swift-utils.patch'
#  }
#
#  if !defined(Package['patch']) {
#    package {'patch': ensure => present }
#  }
#
#  exec { 'patch-swift-utils':
#    path    => ["/usr/bin", "/usr/sbin"],
#    command => "/usr/bin/patch -p1 -N -r - -d \
#                /usr/lib/${::swift::params::python_path}/swift/common/ \
#                </tmp/swift-utils.patch",
#    returns => [0, 1],
#    require => [ [File['/tmp/swift-utils.patch']],[Package['patch', 'swift']]],
#  }
}
