# == Class: openstack::network::neutron_agents
#
# Entry points for Neutron agents setup
#
# === Parameters
#
# [*l2_population*]
#   (optional) Enabled or not ml2 plugin's l2population mechanism driver.
#   Defaults to false
#
# [*agents*]
#   (optional) A list of agents we want enabled
#   Defaults to [ml2-ovs]
#
# [*ha_agents*]
#   (optional) Should be false, "primary", or "slave"
#   primary ensures that any relevant cluster resources will be created.
#   slave ensures that agents are stopped but doesn't attempt to manage them
#   the asumption here is that the slave will get the membership from the
#   cluster and it will manage the resources
#   Defaults to false
#
class openstack::network::neutron_agents (
  $agents     = ['ml2-ovs'],
  $ha_agents  = false,
  $debug      = false,

  # ovs
  $enable_tunneling     = false,
  $tunnel_bridge        = 'br-tun',
  $tunnel_id_ranges     = ['20:100'],
  $integration_bridge   = 'br-int',
  $bridge_mappings      = [],
  $network_vlan_ranges  = ['physnet1:1000:2999'],
  $local_ip             = false,
  $tunnel_types         = [],
  $l2_population        = false,

  # ML2 settings
  $type_drivers          = ['local', 'flat', 'vlan', 'gre', 'vxlan'],
  $tenant_network_types  = ['local', 'flat', 'vlan', 'gre', 'vxlan'],
  $mechanism_drivers     = ['openvswitch', 'linuxbridge'],
  $flat_networks         = ['*'],
  $vxlan_group           = '224.0.0.1',
  $vni_ranges            = ['10:100'],

  # metadata-agent
  $shared_secret,
  $metadata_ip = '127.0.0.1',

  # dhcp-agent
  $resync_interval = 30,
  $net_mtu = undef,
  $isolated_metadata = false,

  # l3-agent
  $metadata_port = 9697,
  $send_arp_for_ha = 3,
  $external_network_bridge = 'br-ex',
  $agent_mode = 'legacy',

  # keystone params
  $admin_password    = 'asdf123',
  $admin_tenant_name = 'services',
  $admin_username    = 'neutron',
  $admin_auth_url    = 'http://localhost:35357/v2.0',
  $auth_region       = 'RegionOne',
) {

  if 'ml2-ovs' in $agents {
    if $net_mtu {
      $bridge_vm             = get_network_role_property('neutron/private', 'interface')
      $physical_network_mtus = regsubst(grep($bridge_mappings, $bridge_vm), $bridge_vm, "${net_mtu}")
    }

    class { 'neutron::plugins::ml2':
      type_drivers          => $type_drivers,
      tenant_network_types  => $tenant_network_types,
      mechanism_drivers     => $mechanism_drivers,
      flat_networks         => $flat_networks,
      network_vlan_ranges   => $network_vlan_ranges,
      tunnel_id_ranges      => $tunnel_id_ranges,
      vxlan_group           => $vxlan_group,
      vni_ranges            => $vni_ranges,
      physical_network_mtus => $physical_network_mtus,
      path_mtu              => $net_mtu,
    }
    class { 'neutron::agents::ml2::ovs':
      integration_bridge         => $integration_bridge,
      tunnel_bridge              => $tunnel_bridge,
      bridge_mappings            => $bridge_mappings,
      enable_tunneling           => $enable_tunneling,
      local_ip                   => $local_ip,
      tunnel_types               => $tunnel_types,
      enable_distributed_routing => $agent_mode ? { 'legacy' => false, default => true},
      l2_population              => $l2_population,
      arp_responder              => $l2_population,
      manage_vswitch             => false,
      manage_service             => true,
      enabled                    => true,
    }

    Service<| title == 'neutron-server' |> -> Service<| title == 'neutron-ovs-agent-service' |>
    Service<| title == 'neutron-server' |> -> Service<| title == 'ovs-cleanup-service' |>
    Exec<| title == 'waiting-for-neutron-api' |> -> Service<| title == 'neutron-ovs-agent-service' |>

    if $ha_agents {
      class {'cluster::neutron::ovs':
        primary   => $ha_agents ? { 'primary' => true, default => false},
      }
    }
  }

  # FIXME(xarses): needs neutron-plugin-linuxbridge* packages
  # if 'linuxbridge' in $agents {
  # }

  if 'metadata' in $agents {
    class {'::neutron::agents::metadata':
      debug          => $debug,
      auth_region    => $auth_region,
      auth_url       => $admin_auth_url,
      auth_user      => $admin_username,
      auth_tenant    => $admin_tenant_name,
      auth_password  => $admin_password,
      shared_secret  => $shared_secret,
      metadata_ip    => $metadata_ip,
      manage_service => true,
      enabled        => true,

    }
    Service<| title == 'neutron-server' |> -> Service<| title == 'neutron-metadata' |>
    Exec<| title == 'waiting-for-neutron-api' |> -> Service<| title == 'neutron-metadata' |>
    if $ha_agents {
      class {'cluster::neutron::metadata':
          primary => $ha_agents ? { 'primary' => true, default => false},
      }
    }
  }

  if 'dhcp' in $agents {
    class { '::neutron::agents::dhcp':
      debug                    => $debug,
      resync_interval          => $resync_interval,
      manage_service           => true,
      dnsmasq_config_file      => $dnsmasq_config_file,
      enable_isolated_metadata => $isolated_metadata,
      dhcp_delete_namespaces   => true,
      enabled                  => true,
    }
    Service<| title == 'neutron-server' |> -> Service<| title == 'neutron-dhcp-service' |>
    Exec<| title == 'waiting-for-neutron-api' |> -> Service<| title == 'neutron-dhcp-service' |>
    if $ha_agents {
      class {'cluster::neutron::dhcp':
        ha_agents         => $agents,
        primary           => $ha_agents ? { 'primary' => true, default => false},
      }
    }
  }

  if 'l3' in $agents {
    class { '::neutron::agents::l3':
      debug                    => $debug,
      metadata_port            => $metadata_port,
      send_arp_for_ha          => $send_arp_for_ha,
      external_network_bridge  => $external_network_bridge,
      manage_service           => true,
      enabled                  => true,
      router_delete_namespaces => true,
      agent_mode               => $agent_mode,
    }
    Service<| title == 'neutron-server' |> -> Service<| title == 'neutron-l3' |>
    Exec<| title == 'waiting-for-neutron-api' |> -> Service<| title == 'neutron-l3' |>
    if $ha_agents {
      # Yes, l3 is supposed to be a defined resource, this will become
      # necessary when we start supporting multiple external routers.
      cluster::neutron::l3 {'default-l3':
        ha_agents         => $agents,
        primary           => $ha_agents ? { 'primary' => true, default => false},
      }
    }
  }
}
