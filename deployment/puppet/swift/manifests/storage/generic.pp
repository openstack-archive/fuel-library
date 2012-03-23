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
    name   => inline_template("<%= scope.lookupvar('::swift::params::${name}_package_name') %>"),
    ensure => $package_ensure,
  }

  file { "/etc/swift/${name}-server/":
    ensure => directory,
    owner  => 'swift',
    group  => 'swift',
  }

  service { "swift-${name}":
    name      => inline_template("<%= scope.lookupvar('::swift::params::${name}_service_name') %>"),
    ensure    => running,
    enable    => true,
    hasstatus => true,
    provider  => $service_provider,
  }

  # TODO - this should be fixed in the upstream
  # packages so that this code can be removed.
  # 931893
  if($::operatingsystem == 'Ubuntu') {
    # I have to fix broken init scripts on Ubuntu
    swift::storage::generic::upstart { $name: }
  }

}
