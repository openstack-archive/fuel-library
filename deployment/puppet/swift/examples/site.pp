#
# This example file is almost the
# same as what I have been using
# to build swift in my environment (which is based on vagrant)

$proxy_local_net_ip='127.0.0.1'
$swift_shared_secret='changeme'
Exec { logoutput => true }

# set up all of the pre steps
# this shoud be run
node pre_swift {

  class { 'apt':}
  # use the swift trunk ppa
  class { 'swift::repo::trunk':}

  # use our apt repo
  apt::source { 'puppet':
    location => 'http://apt.puppetlabs.com/ubuntu',
    release  => 'natty',
    key      => '4BD6EC30',
  }
  # install the latest version of Puppet
  package { 'puppet':
    ensure  => latest,
    require => Apt::Source['puppet'],
  }
}

node swift_all {
  # install curl (we will need it for testing)
  package { 'curl': ensure => present }

  # ensure that sshd is installed
  class { 'ssh::server::install': }

  # install memcached for the proxy
  class { 'memcached':
    listen_ip => $proxy_local_net_ip,
  }

  # set up the swift base deps
  class { 'swift':
    # not sure how I want to deal with this shared secret
    swift_hash_suffix => $swift_shared_secret,
    package_ensure => latest,
  }

  # configure base deps for storage
  class { 'swift::storage': }

  # set up three loopback devices for testing
  swift::storage::loopback { ['1', '2', '3']:
    require => Class['swift'],
  }

  # this is just here temporarily until I can better figure out how to model it
  file { '/etc/swift/ringbuilder.sh':
      content => '
#!/bin/bash
# sets up a basic ring-builder
# which is hard-coded to only work
# for this example

cd /etc/swift

rm -f *.builder *.ring.gz backups/*.builder backups/*.ring.gz

swift-ring-builder object.builder create 18 3 1
swift-ring-builder object.builder add z1-127.0.0.1:6010/1 1
swift-ring-builder object.builder add z2-127.0.0.1:6020/2 1
swift-ring-builder object.builder add z3-127.0.0.1:6030/3 1
swift-ring-builder object.builder rebalance
swift-ring-builder container.builder create 18 3 1
swift-ring-builder container.builder add z1-127.0.0.1:6011/1 1
swift-ring-builder container.builder add z2-127.0.0.1:6021/2 1
swift-ring-builder container.builder add z3-127.0.0.1:6031/3 1
swift-ring-builder container.builder rebalance
swift-ring-builder account.builder create 18 3 1
swift-ring-builder account.builder add z1-127.0.0.1:6012/1 1
swift-ring-builder account.builder add z2-127.0.0.1:6022/2 1
swift-ring-builder account.builder add z3-127.0.0.1:6032/3 1
swift-ring-builder account.builder rebalance
    ',
    mode => '555',
  }~>
  # TODO - figure out why this is failing ;(
  exec { 'build-ring':
    command     => '/etc/swift/ringbuilder.sh',
    refreshonly => true,
    notify      => Service['swift-proxy']
  }

  # configure swift proxy after the run is build
  class { 'swift::proxy':
    account_autocreate => true,
  }

}
