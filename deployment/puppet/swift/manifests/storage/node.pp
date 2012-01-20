define swift::storage::node(
  $mnt_base_dir,
  $owner = 'swift',
  $group  = 'swift',
  $max_connections = 25,
  $storage_local_net_ip = '127.0.0.1'
) {

  Swift::Storage::Device {
    devices => $mnt_base_dir,
    owner => $owner,
    group => $group,
    max_connections => $max_connections,
  }

  swift::storage::device { "60${name}0":
    type => 'object',
  }

  swift::storage::device { "60${name}1":
    type => 'container',
  }

  swift::storage::device { "60${name}2":
    type => 'account',
  }

}
