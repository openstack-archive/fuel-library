#
# Builds out a default storage node
#   a storage node is a device that contains
#   a storage endpoint for account, container, and object
#   on the same mount point
#
# === Parameters:
#
# [*mnt_base_dir*]
#   (optional) The directory where the flat files that store the file system
#   to be loop back mounted are actually mounted at.
#   Defaults to '/srv/node', base directory where disks are mounted to
#
# [*zone*]
#   (required) Zone is the number of the zone this device is in.
#   The zone parameter must be an integer.
#
# [*weight*]
#   (optional) Weight is a float weight that determines how many partitions are
#   put on the device relative to the rest of the devices in the cluster (a good
#   starting point is 100.0xTB on the drive).
#   Add each device that will be initially in the cluster.
#   Defaults to 1.
#
# [*owner*]
#   (optional) Owner (uid) of rsync server.
#   Defaults to 'swift'.
#
# [*group*]
#   (optional) Group (gid) of rsync server.
#   Defaults to 'swift'.
#
# [*max_connections*]
#   (optional) maximum number of simultaneous connections allowed.
#   Defaults to 25.
#
# [*storage_local_net_ip*]
#   (optional) The IP address of the storage server.
#   Defaults to '127.0.0.1'.
#
# ==== DEPRECATED PARAMETERS
#
# [*manage_ring*]
#   This parameter is deprecated and does nothing.
#
define swift::storage::node(
  $mnt_base_dir,
  $zone,
  $weight = 1,
  $owner = 'swift',
  $group  = 'swift',
  $max_connections = 25,
  $storage_local_net_ip = '127.0.0.1',
  # DEPRECATED PARAMETERS
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
    zone   => $zone,
    weight => $weight,
  }

  swift::storage::server { "60${name}1":
    type             => 'container',
    config_file_path => 'container-server.conf',
  }
  ring_container_device { "${storage_local_net_ip}:60${name}1/${name}":
    zone   => $zone,
    weight => $weight,
  }

  swift::storage::server { "60${name}2":
    type             => 'account',
    config_file_path => 'account-server.conf',
  }
  ring_account_device { "${storage_local_net_ip}:60${name}2/${name}":
    zone   => $zone,
    weight => $weight,
  }

}
