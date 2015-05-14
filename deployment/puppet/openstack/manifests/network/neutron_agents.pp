# Not a doc string

# agents should be a list of agents we want enabled
#
# ha_agents should be false, "primary", or "slave"
#  primary ensures that any relevant cluster resources will be created.
#  slave ensures that agents are stopped but doesn't attempt to manage them
#  the asumption here is that the slave will get the membership from the
#  cluster and it will manage the resources


class openstack::network::neutron_agents (
  $agents     = ['ml2-ovs'],
  $ha_agents  = false,
  $verbose    = false,
  $debug      = false,

  # ovs
  $enable_tunneling     = false,
  $tunnel_bridge        = 'br-tun',
  $tunnel_id_ranges     = ['20:100'],
  $integration_bridge   = 'br-int',
  $bridge_mappings      = [],
  $network_vlan_ranges  = ['physnet1:1000:2999'],
  $local_ip             = false,

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
  $use_namespaces = true,
  $dnsmasq_config_file = '/etc/neutron/dnsmasq-neutron.conf',
  $net_mtu = undef,

  # l3-agent
  $metadata_port = 9697,
  $send_arp_for_ha = 3,
  $external_network_bridge = 'br-ex',

  # keystone params
  $admin_password    = 'asdf123',
  $admin_tenant_name = 'services',
  $admin_username    = 'neutron',
  $auth_url          = 'http://localhost:35357/v2.0',
  $auth_region       = 'RegionOne',
) {

  if 'ovs' in $agents {
    class { '::neutron::plugins::ovs':
      tunnel_id_ranges    => $tunnel_id_ranges[0],
      tenant_network_type => $tenant_network_types[0],
      network_vlan_ranges => $network_vlan_ranges[0],
    }
    class { '::neutron::agents::ovs':
      integration_bridge  => $integration_bridge,
      tunnel_bridge       => $tunnel_bridge,
      bridge_mappings     => $bridge_mappings,
      enable_tunneling    => $enable_tunneling,
      local_ip            => $local_ip,
      manage_service      => true,
      enabled             => true,
    }
    Service<| title == 'neutron-server' |> -> Service<| title == 'neutron-ovs-agent-service' |>
    Service<| title == 'neutron-server' |> -> Service<| title == 'ovs-cleanup-service' |>
    Exec<| title == 'waiting-for-neutron-api' |> -> Service<| title == 'neutron-ovs-agent-service' |>

    if $ha_agents {
      class {'cluster::neutron::ovs':
        primary => $ha_agents ? { 'primary' => true, default => false},
      }
    }
  }

  if 'ml2-ovs' in $agents {
    class { 'neutron::plugins::ml2':
      type_drivers          => $type_drivers,
      tenant_network_types  => $tenant_network_types,
      mechanism_drivers     => $mechanism_drivers,
      flat_networks         => $flat_networks,
      network_vlan_ranges   => $network_vlan_ranges,
      tunnel_id_ranges      => $tunnel_id_ranges,
      vxlan_group           => $vxlan_group,
      vni_ranges            => $vni_ranges,
    }
    class { 'neutron::agents::ml2::ovs':
      integration_bridge  => $integration_bridge,
      tunnel_bridge       => $tunnel_bridge,
      bridge_mappings     => $bridge_mappings,
      enable_tunneling    => $enable_tunneling,
      local_ip            => $local_ip,
      manage_service      => true,
      enabled             => true,
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

  if 'linuxbridge' in $agents {
    # FIXME(xarses): needs neutron-plugin-linuxbridge* packages
  }

  if 'metadata' in $agents {
    class {'::neutron::agents::metadata':
      debug          => $debug,
      auth_region    => $auth_region,
      auth_url       => $auth_url,
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
      debug               => $debug,
      resync_interval     => $resync_interval,
      use_namespaces      => $use_namespaces,
      manage_service      => true,
      dnsmasq_config_file => $dnsmasq_config_file,
      enabled             => true,
    }
    Service<| title == 'neutron-server' |> -> Service<| title == 'neutron-dhcp-service' |>
    Exec<| title == 'waiting-for-neutron-api' |> -> Service<| title == 'neutron-dhcp-service' |>
    if $ha_agents {
      class {'cluster::neutron::dhcp':
        ha_agents         => $agents,
        admin_password    => $admin_password,
        admin_tenant_name => $admin_tenant_name,
        admin_username    => $admin_username,
        auth_url          => $auth_url,
        primary           => $ha_agents ? { 'primary' => true, default => false},
      }
    }

    if $net_mtu {
      $mtu = $net_mtu
    } else {
      $mtu = 1500
    }
    file { '/etc/neutron/dnsmasq-neutron.conf':
      owner   => 'root',
      group   => 'root',
      content => template('openstack/neutron/dnsmasq-neutron.conf.erb'),
      require => File['/etc/neutron'],
    } -> Neutron_dhcp_agent_config<||>
    File['/etc/neutron/dnsmasq-neutron.conf'] ~> Service['neutron-dhcp-service']
  }

  if 'l3' in $agents {
    class { '::neutron::agents::l3':
      debug                   => $debug,
      metadata_port           => $metadata_port,
      send_arp_for_ha         => $send_arp_for_ha,
      external_network_bridge => $external_network_bridge,
      manage_service          => true,
      enabled                 => true,
    }
    Service<| title == 'neutron-server' |> -> Service<| title == 'neutron-l3' |>
    Exec<| title == 'waiting-for-neutron-api' |> -> Service<| title == 'neutron-l3' |>
    if $ha_agents {
      # Yes, l3 is supposed to be a defined resource, this will become
      # necessary when we start supporting multiple external routers.
      cluster::neutron::l3 {'default-l3':
        debug             => $debug,
        verbose           => $verbose,
        ha_agents         => $agents,
        admin_password    => $admin_password,
        admin_tenant_name => $admin_tenant_name,
        admin_username    => $admin_username,
        auth_url          => $auth_url,
        primary           => $ha_agents ? { 'primary' => true, default => false},
      }
    }
  }
}
