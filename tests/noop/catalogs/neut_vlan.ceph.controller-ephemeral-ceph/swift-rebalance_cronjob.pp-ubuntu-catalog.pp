class { 'Openstack::Swift::Rebalance_cronjob':
  master_swift_replication_ip => '10.122.14.1',
  name                        => 'Openstack::Swift::Rebalance_cronjob',
  primary_proxy               => 'true',
  ring_rebalance_period       => '2',
  rings                       => ['account', 'object', 'container'],
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

cron { 'swift-rings-rebalance':
  ensure  => 'present',
  command => '/usr/local/bin/swift-rings-rebalance.sh &>/dev/null',
  hour    => '*/2',
  minute  => '15',
  name    => 'swift-rings-rebalance',
  user    => 'swift',
}

cron { 'swift-rings-sync':
  ensure  => 'absent',
  command => '/usr/local/bin/swift-rings-sync.sh &>/dev/null',
  hour    => '*/2',
  minute  => '25',
  name    => 'swift-rings-sync',
  user    => 'swift',
}

file { '/usr/local/bin/swift-rings-rebalance.sh':
  ensure  => 'file',
  content => '#!/bin/bash

swift-ring-builder /etc/swift/account.builder pretend_min_part_hours_passed
swift-ring-builder /etc/swift/account.builder rebalance

swift-ring-builder /etc/swift/object.builder pretend_min_part_hours_passed
swift-ring-builder /etc/swift/object.builder rebalance

swift-ring-builder /etc/swift/container.builder pretend_min_part_hours_passed
swift-ring-builder /etc/swift/container.builder rebalance


',
  group   => 'root',
  mode    => '0755',
  owner   => 'root',
  path    => '/usr/local/bin/swift-rings-rebalance.sh',
}

file { '/usr/local/bin/swift-rings-sync.sh':
  ensure  => 'absent',
  content => '#!/bin/bash

rsync -q -a rsync://10.122.14.1/swift_server/account.ring.gz /etc/swift/account.ring.gz
rsync -q -a rsync://10.122.14.1/swift_server/object.ring.gz /etc/swift/object.ring.gz
rsync -q -a rsync://10.122.14.1/swift_server/container.ring.gz /etc/swift/container.ring.gz

',
  group   => 'root',
  mode    => '0755',
  owner   => 'root',
  path    => '/usr/local/bin/swift-rings-sync.sh',
}

stage { 'main':
  name => 'main',
}

