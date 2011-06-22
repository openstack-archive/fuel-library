# compute.pp
class nova::ubuntu::compute (
  $api_server,
  $rabbit_host,
  $db_host,

  # default to local image service.
  $image_service = undef,
  $glance_api_servers = undef,
  $flat_network_bridge,
  $flat_network_bridge_ip,
  $flat_network_bridge_netmask,
  $rabbit_port = undef,
  $rabbit_userid  = undef,
  $rabbit_virtual_host = undef,
  $db_user = 'nova',
  $db_password = 'nova',
  $db_name = 'nova',
  $enabled = 'false'
) {

  class { "nova":
    logdir              => $logdir,
    verbose             => $verbose,
    image_service       => $image_service,
    rabbit_host         => $rabbit_host,
    rabbit_port         => $rabbit_port,
    rabbit_userid       => $rabbit_userid,
    rabbit_virtual_host => $rabbit_virtual_host,
    sql_connection      => "mysql://${db_user}:${db_password}@${db_host}/${db_name}",
    glance_api_servers  => $glance_api_servers,
  }

  # TODO For now lets worry about FlatManager, then FlatDHCP, etc.
  nova_config {
    'network_manager': value => 'nova.network.manager.FlatManager';
    'flat_network_bridge': value => $flat_network_bridge;
  }
  nova::network::bridge { $flat_network_bridge:
    ip      => $flat_network_bridge_ip,
    netmask => $flat_network_bridge_netmask,
  }

  class { "nova::compute":
    api_server =>  $api_server,
    enabled => $enabled,
  }
}
