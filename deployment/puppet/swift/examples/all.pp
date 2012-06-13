#
# This example file is almost the
# can be used to build out a sample swift all in one environment
#
$swift_local_net_ip='127.0.0.1'

$swift_shared_secret='changeme'

Exec { logoutput => true }

package { 'curl': ensure => present }

class { 'ssh::server::install': }

class { 'memcached':
  listen_ip => $swift_local_net_ip,
}

class { 'swift':
  # not sure how I want to deal with this shared secret
  swift_hash_suffix => $swift_shared_secret,
  package_ensure => latest,
}

# === Configure Storage

class { 'swift::storage':
  storage_local_net_ip => $swift_local_net_ip
}

# create xfs partitions on a loopback device and mounts them
swift::storage::loopback { ['4', '2', '3']:
  require => Class['swift'],
}

# sets up storage nodes which is composed of a single
# device that contains an endpoint for an object, account, and container

Swift::Storage::Node {
  mnt_base_dir         => '/srv/node',
  weight               => 1,
  manage_ring          => true,
  storage_local_net_ip => $swift_local_net_ip,
}

swift::storage::node { '4':
  zone    => 4,
  require => Swift::Storage::Loopback[4],
}

swift::storage::node { '2':
  zone    => 2,
  require => Swift::Storage::Loopback[2],
}

swift::storage::node { '3':
  zone    => 3,
  require => Swift::Storage::Loopback[3],
}

class { 'swift::ringbuilder':
  part_power     => '18',
  replicas       => '3',
  min_part_hours => 1,
  require        => Class['swift'],
}


# TODO should I enable swath in the default config?
class { 'swift::proxy':
  proxy_local_net_ip => $swift_local_net_ip,
  pipeline           => ['healthcheck', 'cache', 'tempauth', 'proxy-server'],
  account_autocreate => true,
  require            => Class['swift::ringbuilder'],
}
class { ['swift::proxy::healthcheck', 'swift::proxy::cache', 'swift::proxy::tempauth']: }
