#
# Builds out a default storage node
#   a storage node is a device that contains
#   a storage endpoint for account, container, and object
#   on the same mount point
#
define swift::storage::node(
  $mnt_base_dir,
  $zone,
  $weight = 1,
  $owner = 'swift',
  $group  = 'swift',
  $max_connections = 25,
  $storage_local_net_ip = '127.0.0.1',
  $manage_ring = true
) {

  validate_re($zone, '^\d+$', 'The zone parameter must be an integer')

  Swift::Storage::Server {
    storage_local_net_ip => $storage_local_net_ip,
    devices              => $mnt_base_dir,
    max_connections      => $max_connections,
    owner                => $owner,
    group                => $group,
  }

  swift::storage::server { "60${name}0":
    type             => 'object',
    config_file_path => 'object-server.conf',
  }
  ring_object_device { "${storage_local_net_ip}:60${name}0/${name}":
    zone        => $zone,
    weight      => $weight,
  }

  swift::storage::server { "60${name}1":
    type             => 'container',
    config_file_path => 'container-server.conf',
  }
  ring_container_device { "${storage_local_net_ip}:60${name}1/${name}":
    zone        => $zone,
    weight      => $weight,
  }

  swift::storage::server { "60${name}2":
    type             => 'account',
    config_file_path => 'account-server.conf',
  }
  ring_account_device { "${storage_local_net_ip}:60${name}2/${name}":
    zone        => $zone,
    weight      => $weight,
  }

}
