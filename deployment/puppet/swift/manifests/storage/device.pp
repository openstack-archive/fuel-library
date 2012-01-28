#
# I am not sure if this is the right name
#   - should it be device?
#
#  name - is going to be port
define swift::storage::device(
  $type,
  $devices = '/srv/node',
  $owner = 'swift',
  $group  = 'swift',
  $max_connections = 25,
  $storage_local_net_ip = '127.0.0.1'
) {

  validate_re($name, '^\d+$')
  validate_re($type, '^object|container|account$')
  # TODO - validate that name is an integer

  # This makes me think that perhaps the rsync class
  # should be split into install and config
  #
  Swift::Storage::Device[$name] ~> Service['rsync']

  $bind_port = $name

  rsync::server::module { "${type}${name}":
    path => $devices,
    lock_file => "/var/lock/${type}${name}.lock",
    uid => $owner,
    gid => $group,
    max_connections => $max_connections,
    read_only => false,
  }

  file { "/etc/swift/${type}-server/${name}.conf":
    content => template("swift/${type}-server.conf.erb"),
    owner   => $owner,
    group   => $group,
  }

}
