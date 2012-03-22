#
# I am not sure if this is the right name
#   - should it be device?
#
#  name - is going to be port
define swift::storage::server(
  $type,
  $storage_local_net_ip,
  $devices = '/srv/node',
  $owner = 'swift',
  $group  = 'swift',
  $max_connections = 25,
  # this parameters needs to be specified after type and name
  $config_file_path = "${type}-server/${name}.conf"
) {

  include "swift::storage::$type"

  validate_re($name, '^\d+$')
  validate_re($type, '^object|container|account$')
  # TODO - validate that name is an integer

  $bind_port = $name

  rsync::server::module { "${type}${name}":
    path => $devices,
    lock_file => "/var/lock/${type}${name}.lock",
    uid => $owner,
    gid => $group,
    max_connections => $max_connections,
    read_only => false,
  }

  file { "/etc/swift/${config_file_path}":
    content => template("swift/${type}-server.conf.erb"),
    owner   => $owner,
    group   => $group,
  }

}
