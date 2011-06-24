#
# TODO - this is currently hardcoded to be a xenserver
class nova::all(
  $db_password,
  $db_name = 'nova',
  $db_user = 'nova',
  $db_host = 'localhost',

  $rabbit_port = undef,
  $rabbit_userid = undef,
  $rabbit_password = undef,
  $rabbit_virtual_host = undef,
  $rabbit_host = undef,

  $libvirt_type = 'kvm',

  $flat_network_bridge  = 'br100',
  $flat_network_bridge_ip  = '11.0.0.1',
  $flat_network_bridge_netmask  = '255.255.255.0',

  $nova_network = '11.0.0.0',
  $available_ips = '256',

  $image_service = 'nova.image.glance.GlanceImageService',
  $glance_api_servers = 'localhost:9292',
  $glance_host = 'localhost',
  $glance_port = '9292',

  $admin_user = 'novaadmin',
  $project_name = 'nova',

  $verbose = undef
) {


  class { 'nova::rabbitmq':
    port         => $rabbit_port,
    userid       => $rabbit_userid,
    password     => $rabbit_password,
    virtual_host => $rabbit_virtual_host,
  }

  class { "nova":
    verbose             => $verbose,
    sql_connection      => "mysql://${db_user}:${db_password}@${db_host}/${db_name}",
    image_service       => $image_service,
    glance_api_servers  => $glance_api_servers,
    glance_host         => $glance_host,
    glance_port         => $glance_port,
    rabbit_host         => $rabbit_host,
    rabbit_port         => $rabbit_port,
    rabbit_userid       => $rabbit_userid,
    rabbit_password     => $rabbit_password,
    rabbit_virtual_host => $rabbit_virtual_host,
  }

  class { "nova::api": enabled => true }

  class { "nova::compute":
    api_server     => $ipaddress,
    enabled        => true,
  }
  class { 'nova::compute::libvirt':
    libvirt_type                => $libvirt_type,
    flat_network_bridge         => $flat_network_bridge,
    flat_network_bridge_ip      => $flat_network_bridge_ip,
    flat_network_bridge_netmask => $flat_network_bridge_netmask,
  }

  class { "nova::network::flat":
    enabled                     => true,
    flat_network_bridge         => $flat_network_bridge,
    flat_network_bridge_ip      => $flat_network_bridge_ip,
    flat_network_bridge_netmask => $flat_network_bridge_netmask,
    configure_bridge            => false,
  }

  class { "nova::objectstore": enabled => true }
  class { "nova::scheduler": enabled => true }
  class { 'nova::db':
    # pass in db config as params
    password => $db_password,
    dbname   => $db_name,
    user     => $db_user,
    host     => $db_host,
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

  # set up glance server
  class { 'glance::api':
    swift_store_user => 'foo_user',
    swift_store_key => 'foo_pass',
  }

  class { 'glance::registry': }

}
