#
# This example file is almost the
# same as what I have been using
# to build swift in my environment (which is based on vagrant)

$proxy_local_net_ip='127.0.0.1'
$swift_shared_secret='changeme'
Exec { logoutput => true }

package { 'curl': ensure => present }
class { 'ssh::server::install': }
class { 'memcached':
  listen_ip => $proxy_local_net_ip,
}
class { 'swift':
  # not sure how I want to deal with this shared secret
  swift_hash_suffix => $swift_shared_secret,
  package_ensure => latest,
}
swift::storage::loopback { ['1', '2', '3']:
  require => Class['swift'],
}

Ring_object_device { weight => 1 }
Ring_container_device { weight => 1 }
Ring_account_device { weight => 1 }

ring_object_device { '127.0.0.1:6010':
  zone        => 1,
  device_name => '1',
}
ring_object_device { '127.0.0.1:6020':
  zone        => 2,
  device_name => '2',
}
ring_object_device { '127.0.0.1:6030':
  zone        => 3,
  device_name => '3',
}

ring_container_device { '127.0.0.1:6011':
  zone        => 1,
  device_name => '1',
}
ring_container_device { '127.0.0.1:6021':
  zone        => 2,
  device_name => '2',
}
ring_container_device { '127.0.0.1:6031':
  zone        => 3,
  device_name => '3',
}

ring_account_device { '127.0.0.1:6012':
  zone        => 1,
  device_name => '1',
}
ring_account_device { '127.0.0.1:6022':
  zone        => 2,
  device_name => '2',
}
ring_account_device { '127.0.0.1:6032':
  zone        => 3,
  device_name => '3',
}

class { 'swift::ringbuilder':
  part_power     => '18',
  replicas       => '3',
  min_part_hours => 1,
  require        => Class['swift'],
}

class { 'swift::storage': }

# TODO should I enable swath in the default config?
class { 'swift::proxy':
  account_autocreate => true,
  require            => Class['swift::ringbuilder'],
}

