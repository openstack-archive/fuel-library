# Performs all global configuration required
# for creating a swift storage node.
#  Includes:
#    installing an rsync server
#    installs storeage packages (object,account,containers)
# == Parameters
#  [*storeage_local_net_ip*]
#  [*package_ensure*]
# == Dependencies
#
# == Examples
#
# == Authors
#
#   Dan Bode dan@puppetlabs.com
#
# == Copyright
#
# Copyright 2011 Puppetlabs Inc, unless otherwise noted.
#
class swift::storage(
  $package_ensure = 'present',
  # TODO - should this default to 0.0.0.0?
  $storage_local_net_ip = '127.0.0.1',
  $devices = '/srv/nodes'
) inherits swift {


  class{ 'rsync::server':
    use_xinetd => false,
    address => $storage_local_net_ip,
  }

  Service {
    ensure    => running,
    enable    => true,
    hasstatus => true,
    subscribe => Service['rsync'],
  }

  File {
    owner => 'swift',
    group => 'swift',
  }

  Swift::Storage::Server {
    devices               => $devices,
    storage_local_net_ip => $storage_local_net_ip,
  }

  # package dependencies
  package { ['xfsprogs', 'parted']:
    ensure => 'present'
  }

  package { 'swift-account':
    ensure => $package_ensure,
  }

  swift::storage::server { '6002':
    type             => 'account',
    config_file_path => 'account-server.conf',
  }

  file { '/etc/swift/account-server/':
    ensure => directory,
  }

  service { 'swift-account':
    provider  => 'upstart',
  }

  # container server configuration
  package { 'swift-container':
    ensure => $package_ensure,
  }

  swift::storage::server { '6001':
    type             => 'container',
    config_file_path => 'container-server.conf',
  }

  file { '/etc/swift/container-server/':
    ensure => directory,
  }

  service { 'swift-container':
    provider  => 'upstart',
  }

  # object server configuration
  package { 'swift-object':
    ensure => $package_ensure,
  }

  swift::storage::server { '6000':
    type             => 'object',
    config_file_path => 'object-server.conf',
  }

  file { '/etc/swift/object-server/':
    ensure => directory,
  }

  service { 'swift-object':
    provider  => 'upstart',
  }

  define upstart() {
    file { "/etc/init/swift-${name}.conf":
      mode   => '0644',
      owner  => 'root',
      group  => 'root',
      source => "puppet:///modules/swift/swift-${name}.conf.upstart",
      before => Service["swift-${name}"],
    }
  }

  swift::storage::upstart { ['object', 'container', 'account']: }

}
