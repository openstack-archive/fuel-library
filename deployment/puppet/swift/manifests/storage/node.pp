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

  swift::storage::device::object { "60${name}0":
    devices              => $mnt_base_dir,
    device_name          => $name,
    zone                 => $zone,
    weight               => $weight,
    owner                => $owner,
    group                => $group,
    max_connections      => $max_connections,
    storage_local_net_ip => $storage_local_net_ip,
    manage_ring          => $manage_ring,
  }

  swift::storage::device::container { "60${name}1":
    devices              => $mnt_base_dir,
    device_name          => $name,
    zone                 => $zone,
    weight               => $weight,
    owner                => $owner,
    group                => $group,
    max_connections      => $max_connections,
    storage_local_net_ip => $storage_local_net_ip,
    manage_ring          => $manage_ring,
  }

  swift::storage::device::account { "60${name}2":
    devices              => $mnt_base_dir,
    device_name          => $name,
    zone                 => $zone,
    weight               => $weight,
    owner                => $owner,
    group                => $group,
    max_connections      => $max_connections,
    storage_local_net_ip => $storage_local_net_ip,
    manage_ring          => $manage_ring,
  }

}
