#
# I am not sure if this is the right name
#   - should it be device?
#
#  name - is going to be port
define swift::storage::device::container(
  $device_name,
  $zone,
  $weight = 1,
  $storage_local_net_ip = '127.0.0.1',
  $devices = '/srv/node',
  $owner = 'swift',
  $group  = 'swift',
  $max_connections = 25,
  $manage_ring = true
) {

  swift::storage::device { $name:
    type                 => 'container',
    storage_local_net_ip => $storage_local_net_ip,
    devices              => $devices,
    owner                => $owner,
    group                => $group,
    max_connections      => $max_connections,
  }

  # if we are managing the ring on this node
  if($manage_ring) {
    ring_container_device { "${storage_local_net_ip}:${name}":
      zone        => $zone,
      device_name => $device_name,
      weight      => $weight,
    }
  } else {
    # if we are not managing the ring on this node, just export the resource
    @@ring_container_device { "${storage_local_net_ip}:${name}":
      zone        => $zone,
      device_name => $device_name,
      weight      => $weight,
    }

  }

}
