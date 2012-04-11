#
# TODO - this is currently hardcoded to be a xenserver
class nova::controller(
  $db_password,
  $db_name = 'nova',
  $db_user = 'nova',
  $db_host = 'localhost',
  $db_allowed_hosts = undef,

  $rabbit_port = undef,
  $rabbit_userid = undef,
  $rabbit_password = undef,
  $rabbit_virtual_host = undef,
  $rabbit_host = undef,

  $libvirt_type = 'qemu',

  $flat_network_bridge  = 'br100',
  $flat_network_bridge_ip  = '11.0.0.1',
  $flat_network_bridge_netmask  = '255.255.255.0',

  $flat_interface = undef,
  $flat_dhcp_start = undef,
  $flat_injected = undef,

  $vlan_interface = 'eth1',
  $vlan_start = 1000,

  $network_manager = undef,
  $multi_host_networking = false,
  $nova_network = '11.0.0.0/24',
  $floating_network = '10.128.0.0/24',
  $available_ips = '256',

  $image_service = 'nova.image.glance.GlanceImageService',
  $glance_api_servers = 'localhost:9292',

  $admin_user = 'novaadmin',
  $project_name = 'nova',

  $verbose = undef,

  $lock_path = undef
) {


  class { "nova":
    verbose               => $verbose,
    sql_connection        => "mysql://${db_user}:${db_password}@${db_host}/${db_name}",
    image_service         => $image_service,
    glance_api_servers    => $glance_api_servers,
    rabbit_host           => $rabbit_host,
    rabbit_port           => $rabbit_port,
    rabbit_userid         => $rabbit_userid,
    rabbit_password       => $rabbit_password,
    rabbit_virtual_host   => $rabbit_virtual_host,
    lock_path             => $lock_path,
    network_manager       => $network_manager,
    multi_host_networking => $multi_host_networking,
    flat_network_bridge   => $flat_network_bridge,
    vlan_interface        => $vlan_interface,
    vlan_start            => $vlan_start,
  }

  class { "nova::api": enabled => true }

  # in multi_host networking mode nova-network does not run on the controller
  if !$multi_host_networking {
    case $network_manager {
      'nova.network.manager.FlatManager': {
        class { "nova::network::flat":
          enabled                     => true,
          flat_network_bridge         => $flat_network_bridge,
          flat_network_bridge_ip      => $flat_network_bridge_ip,
          flat_network_bridge_netmask => $flat_network_bridge_netmask,
          configure_bridge            => false,
        }
      }
      'nova.network.manager.FlatDHCPManager': {
        class { "nova::network::flatdhcp":
          enabled                     => true,
          flat_interface              => $flat_interface,
          flat_dhcp_start             => $flat_dhcp_start,
          flat_injected               => $flat_injected,
          flat_network_bridge_netmask => $flat_network_bridge_netmask,
          configure_bridge            => false,
        }
      }
      'nova.network.manager.VlanManger': {
        class { "nova::network::vlan":
          enabled => true,
        }
      }
      default: {
        fail("Unsupported network manager: ${network_manager} The supported network managers are nova.network.manager.FlatManager, nova.network.FlatDHCPManager and nova.network.manager.VlanManager")
      }
    }
  }

  class { "nova::objectstore":
    enabled => true,
  }

  class { "nova::cert":
    enabled => true,
  }

  class { "nova::volume":
    enabled => true,
  }

  class { "nova::scheduler": enabled => true }

  nova::manage::admin { $admin_user: }
  nova::manage::project { $project_name:
    owner => $admin_user,
  }

  nova::manage::network { "${project_name}-net-${nova_network}":
    network       => $nova_network,
    available_ips => $available_ips,
    require       => Nova::Manage::Project[$project_name],
  }

  nova::manage::floating { "${project_name}-floating-${floating_network}":
    network       => $floating_network,
    require       => Nova::Manage::Project[$project_name],
  }
}
