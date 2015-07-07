# Creates the files packages and services that are
# needed to deploy each type of storage server.
#
# == Parameters
#  [*enabled*]
#    (optional) Should the service be enabled.
#    Defaults to true
#
#  [*manage_service*]
#    (optional) Whether the service should be managed by Puppet.
#    Defaults to true.
#
#  [*package_ensure*]
#    (optional) The desired ensure state of the swift storage packages.
#    Defaults to present.
#
#  [*service_provider*]
#    (optional) The provider to use for the service
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
  $manage_service   = true,
  $enabled          = true,
  $package_ensure   = 'present',
  $service_provider = $::swift::params::service_provider
) {

  include ::swift::params

  Class['swift::storage'] -> Swift::Storage::Generic[$name]
  Swift_config<| |> ~> Service["swift-${name}"]

  validate_re($name, '^object|container|account$')

  package { "swift-${name}":
    ensure => $package_ensure,
    # this is a way to dynamically build the variables to lookup
    # sorry its so ugly :(
    name   => inline_template("<%= scope.lookupvar('::swift::params::${name}_package_name') %>"),
    tag    => 'openstack',
    before => Service["swift-${name}", "swift-${name}-replicator"],
  }

  file { "/etc/swift/${name}-server/":
    ensure => directory,
    owner  => 'swift',
    group  => 'swift',
  }

  if $manage_service {
    if $enabled {
      $service_ensure = 'running'
    } else {
      $service_ensure = 'stopped'
    }
  }

  service { "swift-${name}":
    ensure    => $service_ensure,
    name      => inline_template("<%= scope.lookupvar('::swift::params::${name}_service_name') %>"),
    enable    => $enabled,
    hasstatus => true,
    provider  => $service_provider,
    subscribe => Package["swift-${name}"],
  }

  service { "swift-${name}-replicator":
    ensure    => $service_ensure,
    name      => inline_template("<%= scope.lookupvar('::swift::params::${name}_replicator_service_name') %>"),
    enable    => $enabled,
    hasstatus => true,
    provider  => $service_provider,
    subscribe => Package["swift-${name}"],
  }

}
