#
# TODO - this is currently hardcoded to be a xenserver
class nova::canonical::all(
  $logdir,
  $verbose,
  $sql_connection='mysql://root:<password>@127.0.0.1/nova',
  $network_manager,
  $image_service,
  $flat_network_bridge = 'xenbr0',
  $glance_host,
  $glance_port,
  $allow_admin_api = 'true',
  $rabbit_host=$::ipaddress,
  $rabbit_password,
  $rabbit_port,
  $rabbit_userid,
  $rabbit_virtual_host,
  $state_path,
  $lock_path,
  $service_down_time,
  $host
  # they are only supporting libvirt for now
) {

  class { "nova":
    logdir               => $logdir,
    verbose              => $verbose,
    sql_connection       => $sql_connection,
    network_manager      => $network_manager,
    image_service        => $image_service,
    flat_network_bridge  => $flat_network_bridge,
    glance_host          => $glance_host,
    glance_port          => $glance_port,
    allow_admin_api      => $allow_admin_api,
    rabbit_host          => $rabbit_host,
    rabbit_password      => $rabbit_password,
    rabbit_port          => $rabbit_port,
    rabbit_userid        => $rabbit_userid,
    rabbit_virtual_host  => $rabbit_virtual_host,
    state_path           => $state_path,
    lock_path            => $lock_path,
    service_down_time    => $service_down_time,
  }

  class { "nova::api": enabled => false }
  # class { 'nova::compute::libvirt': }
  class { "nova::compute":
    enabled => false
  }
  class { "nova::network": enabled => false }
  class { "nova::objectstore": enabled => false }
  class { "nova::scheduler": enabled => false }
  class { 'nova::db':
    # pass in db config as params
    password => 'password',
    name     => 'nova',
    user     => 'nova',
    host     => 'localhost',
  }
}
