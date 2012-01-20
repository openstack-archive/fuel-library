#
# class for building out a storage node
#
class swift::storage(
  $package_ensure = 'present',
  # TODO - should this default to 0.0.0.0?
  $storage_local_net_ip = '127.0.0.1'
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

  # package dependencies
  package { ['xfsprogs', 'parted']:
    ensure => 'present'
  }

  package { 'swift-account':
    ensure => $package_ensure,
  }

  file { '/etc/swift/account-server.conf':
    ensure  => present,
    mode    => 0660,
    content => template('swift/account-server.conf.erb')
  }

  file { '/etc/swift/account-server/':
    ensure => directory,
  }

  service { 'swift-account':
    provider  => 'upstart',
  }

  package { 'swift-container':
    ensure => $package_ensure,
  }

  file { '/etc/swift/container-server.conf':
    ensure  => present,
    mode    => 0660,
    content => template('swift/container-server.conf.erb')
  }

  file { '/etc/swift/container-server/':
    ensure => directory,
  }

  service { 'swift-container':
    provider  => 'upstart',
  }

  package { 'swift-object':
    ensure => $package_ensure,
  }

  file { '/etc/swift/object-server.conf':
    ensure  => present,
    mode    => 0660,
    content => template('swift/object-server.conf.erb')
  }

  file { '/etc/swift/object-server/':
    ensure => directory,
  }

  service { 'swift-object':
    provider  => 'upstart',
  }
}
