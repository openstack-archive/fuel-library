#
# TODO - this is currently hardcoded to be a xenserver
class nova::ubuntu::cc (
  $db_password,
  $db_name = 'nova',
  $db_user = 'nova',
  $db_host = 'localhost',
  $db_allowed_hosts = undef,

  $flat_network_bridge  = 'br100',
  $flat_network_bridge_ip  = '11.0.0.1',
  $flat_network_bridge_netmask  = '255.255.255.0',

  $image_service = 'nova.image.local.LocalImageService',

  $glance_api_servers = 'localhost:9292',

  $nova_network = '11.0.0.0',
  $available_ips = '256',

  $admin_user = 'novaadmin',
  $project_name = 'nova'
) {


  # work around hostname bug, LP #653405
  host { $hostname:
    ip => $ipaddress,
    host_aliases => $fqdn,
  }
  class { 'nova::rabbitmq':
    port         => $rabbitmq_port,
    userid       => $rabbitmq_userid,
    password     => $rabbitmq_password,
    virtual_host => $rabbitmq_virtual_host,
    require      => Host[$hostname],
  }

  class { "nova":
    logdir              => $logdir,
    verbose             => $verbose,
    sql_connection      => "mysql://${db_user}:${db_password}@${db_host}/${db_name}",
    image_service       => $image_service,
    glance_api_servers  => $glance_api_servers,
  }

  class { "nova::api": enabled => true }

  class { "nova::network::flat":
    enabled                     => true,
    flat_network_bridge         => $flat_network_bridge,
    flat_network_bridge_ip      => $flat_network_bridge_ip,
    flat_network_bridge_netmask => $flat_network_bridge_netmask,
  }

  class { "nova::objectstore": enabled => true }
  class { "nova::scheduler": enabled => true }
  class { 'nova::db':
    # pass in db config as params
    password      => $db_password,
    name          => $db_name,
    user          => $db_user,
    host          => $db_host,
    allowed_hosts => $db_allowed_hosts,
  }

  nova::manage::admin { $admin_user: }
  nova::manage::project { $project_name:
    owner => $admin_user,
  }

  nova::manage::network { "${project_name}-net-${nova_network}":
    network       => $nova_network,
    available_ips => $available_ips,
    require       => Nova::Manage::Project[$project_name],
  }

}
