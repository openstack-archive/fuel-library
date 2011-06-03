#
# TODO - this is currently hardcoded to be a xenserver
class nova::canonical::all(
  $logdir,
  $verbose = false,
  $db_password,
  $db_name = 'nova',
  $db_user = 'nova',
  $db_host = 'localhost',
  $network_manager,
  $image_service,
  $flat_network_bridge  = 'br100',
  $glance_host,
  $glance_port,
  $allow_admin_api = 'true',
  $rabbit_host = undef,
  $rabbit_password = unfef,
  $rabbit_port = undef,
  $rabbit_userid = undef,
  $rabbit_virtual_host = undef,
  $state_path,
  $lock_path,
  $service_down_time,
  $host,
  $admin_user = 'novaadmin',
  $project_name = 'nova'
  # they are only supporting libvirt for now
) {


  # work around hostname bug, LP #653405
  host { $hostname:
    ip => $ipaddress,
    host_aliases => $fqdn,
  }
  class { 'nova::rabbitmq':
    require => Host[$hostname],
  }

  class { "nova":
    logdir               => $logdir,
    verbose              => $verbose,
    sql_connection       => "mysql://${db_user}:${db_password}@${db_host}/${db_name}",
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
    password => $db_password,
    name     => $db_name,
    user     => $db_user,
    host     => $db_host,
  }

  nova::manage::admin { $admin_user: }
  nova::manage::project { $project_name:
    owner => $admin_user,
  }
}
