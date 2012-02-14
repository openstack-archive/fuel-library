# Performs all global configuration required
# for creating a swift storage node.
#  Includes:
#    installing an rsync server
#    installs storeage packages (object,account,containers)
# == Parameters
#  [*storeage_local_net_ip*]
#  [*package_ensure*]
#  [*object_port*] Port where object storage server should be hosted.
#    Optional. Defaults to 6000.
#  [*container_port*] Port where the container storage server should be hosted.
#    Optional. Defaults to 6001.
#  [*account_port*] Port where the account storage server should be hosted.
#    Optional. Defaults to 6002.
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
  $object_port = '6000',
  $container_port = '6001',
  $account_port = '6002'
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

  swift::storage::server { $account_port:
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

  swift::storage::server { $container_port:
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

  swift::storage::server { $object_port:
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
