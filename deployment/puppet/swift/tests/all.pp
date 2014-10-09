#
# This example file is almost the
# can be used to build out a sample swift all in one environment
#
$swift_local_net_ip='127.0.0.1'

$swift_shared_secret='changeme'

Exec { logoutput => true }

package { 'curl': ensure => present }


class { 'memcached':
  listen_ip => $swift_local_net_ip,
}

class { 'swift':
  # not sure how I want to deal with this shared secret
  swift_hash_suffix => $swift_shared_secret,
  package_ensure    => latest,
}

# === Configure Storage

class { 'swift::storage':
  storage_local_net_ip => $swift_local_net_ip
}

# create xfs partitions on a loopback device and mounts them
swift::storage::loopback { '2':
  require => Class['swift'],
}

# sets up storage nodes which is composed of a single
# device that contains an endpoint for an object, account, and container

swift::storage::node { '2':
  mnt_base_dir         => '/srv/node',
  weight               => 1,
  manage_ring          => true,
  zone                 => '2',
  storage_local_net_ip => $swift_local_net_ip,
  require              => Swift::Storage::Loopback[2] ,
}

class { 'swift::ringbuilder':
  part_power     => '18',
  replicas       => '1',
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
