# Creates the files packages and services that are
# needed to deploy each type of storage server.
#
# == Parameters
#  [*package_ensure*] The desired ensure state of the swift storage packages.
#    Optional. Defaults to present.
#  [*service_provider*] The provider to use for the service
#
# == Dependencies
#  Requires Class[swift::storage]
# == Examples
#
# == Authors
#
#   Dan Bode dan@puppetlabs.com
#
# == Copyright
#
# Copyright 2011 Puppetlabs Inc, unless otherwise noted.
define swift::storage::generic(
  $package_ensure   = 'present',
  $service_provider = $::swift::params::service_provider
) {

  include swift::params

  Class['swift::storage'] -> Swift::Storage::Generic[$name]

  validate_re($name, '^object|container|account$')

  package { "swift-${name}":
    ensure => $package_ensure,
    # this is a way to dynamically build the variables to lookup
    # sorry its so ugly :(
    name   => inline_template("<%= scope.lookupvar('::swift::params::${name}_package_name') %>"),
    before => Service["swift-${name}", "swift-${name}-replicator"],
  }

  file { "/etc/swift/${name}-server/":
    ensure => directory,
    owner  => 'swift',
    group  => 'swift',
  }

  service { "swift-${name}":
    ensure    => running,
    name      => inline_template("<%= scope.lookupvar('::swift::params::${name}_service_name') %>"),
    enable    => true,
    hasstatus => true,
    provider  => $service_provider,
    subscribe => Package["swift-${name}"],
  }

  if $::osfamily == "RedHat" {
    $service_name = "openstack-swift-${name}-replicator"
  } else {
    $service_name = "swift-${name}-replicator"
  }


  service { "swift-${name}-replicator":
    ensure    => running,
    name      => inline_template("<%= scope.lookupvar('::swift::params::${name}_replicator_service_name') %>"),
    enable    => true,
    hasstatus => true,
    provider  => $service_provider,
    subscribe => Package["swift-${name}"],
  }

  Package["swift-${name}"] ~> Service["swift-${name}-replicator"]

}
