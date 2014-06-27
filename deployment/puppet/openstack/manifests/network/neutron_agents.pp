# Not a doc string

# agents should be a list of agents we want enabled
#
# ha_agents should be false, "primary", or "slave"
#  primary ensures that any relevant cluster resources will be created.
#  slave ensures that agents are stopped but doesn't attempt to manage them
#  the asumption here is that the slave will get the membership from the
#  cluster and it will manage the resources


class openstack::network::neutron_agents (
  $agents = ['ml2-ovs',]
  $ha_agents = false,

  #ovs
  $tunnel_bridge = 'br-tun',
  $enable_tunneling = false,
  $intergration_bridge = 'br-int',
  #$tunnel_id_ranges = '1:1000',
  #$tenant_network_types = 'gre',
  #$network_vlan_ranges = 'physnet1:1000:2999',
  $bridge_mappings = [],
  $local_ip = false,

  #ML2 settings
  $type_drivers          = ['local', 'flat', 'vlan', 'gre', 'vxlan'],
  $tenant_network_types  = ['local', 'flat', 'vlan', 'gre', 'vxlan'],
  $mechanism_drivers     = ['openvswitch', 'linuxbridge'],
  $flat_networks         = ['*'],
  $network_vlan_ranges   = ['physnet1:1000:2999'],
  $tunnel_id_ranges      = ['20:100'],
  $vxlan_group           = '224.0.0.1',
  $vni_ranges            = ['10:100'],

  #metadata-agent
  $shared_secret,
  $metadata_ip = '127.0.0.1',

  #dhcp-agent
  $resync_interval = 30,
  $use_namespaces = true,

  #l3-agent
  $metadata_port = 9697,
  $send_arp_for_ha = 3,
  $external_network_bridge = 'br-ex'


  # keystone params
  $admin_password    = 'asdf123',
  $admin_tenant_name = 'services',
  $admin_username    = 'neutron',
  $auth_url          = 'http://localhost:35357/v2.0',
  $auth_region       = 'RegionOne',

  # imported from openstack::neutron_router
  $verbose                  = false,
  $debug                    = false,
) {

  if 'ovs' in $agents {
    class { '::neutron::plugins::ovs':
      tunnel_id_ranges    => $tunnel_id_ranges,
      tenant_network_type => $tenant_network_types,
      network_vlan_ranges => $network_vlan_ranges,
    }
    class { 'neutron::agents::ovs':
      intergration_bridge => $intergration_bridge,
      tunnel_bridge       => $tunnel_bridge,
      bridge_mappings     => $bridge_mappings,
      enable_tunneling    => $enable_tunneling,
      local_ip            => $local_ip,
    }
    if $ha_agents == 'primary' {
      class {'cluster::neutron::ovs': }
    } elsif $ha_agents == "slave" {
      Neutron::Agents::Ovs {
        enabled         => false,
        manage_service  => false,
      }
    }

  }
  if 'ml2-ovs' in $agents {
    class { 'neutron::plugins::ml2':
      type_drivers => $type_drivers,
      tenant_network_types  => $tenant_network_types,
      mechanism_drivers     => $mechanism_drivers,
      flat_networks         => $flat_networks,
      network_vlan_ranges   => $network_vlan_ranges,
      tunnel_id_ranges      => $tunnel_id_ranges,
      vxlan_group           => $vxlan_group,
      vni_ranges            => $vni_ranges,
    }
    class { 'neutron::agents::ml2::ovs':
      intergration_bridge => $intergration_bridge,
      tunnel_bridge       => $tunnel_bridge,
      bridge_mappings     => $bridge_mappings,
      enable_tunneling    => $enable_tunneling,
      local_ip            => $local_ip,
    }
    if $ha_agents == 'primary' {
      class {'cluster::neutron::ovs': }
    } elsif $ha_agents == 'slave' {
      Neutron::Agents::Ml2::Ovs {
        enabled         => false,
        manage_service  => false,
      }
    }
  }

  if 'linuxbridge' in $agents {}

  if 'metadata' in $agents {
    class {'::neutron::agents::metadata':
      debug         => $debug,
      auth_region   => $auth_region,
      auth_url      => $auth_url,
      auth_user     => $admin_username,
      auth_tenant   => $admin_tenant_name,
      shared_secret => $shared_secret,
      metadata_ip   => $metadata_ip
    }
    if $ha_agents == 'primary' {
      class {'cluster::neutron::metadata': }
    } elsif $ha_agents == 'slave' {
      Neutron::Agents::Metadata {
        enabled         => false,
        manage_service  => false,
        before          => Cluster::Corosync::Cs_service['neutron-metadata-agent']
      }
    }
  }

  if 'dhcp' in $agents {
    class { '::neutron::agents::dhcp':
      debug           => $debug,
      resync_interval => $resync_interval,
      use_namespaces  => $use_namespaces,
    }
    if $ha_agents == 'primary' {
      class {'cluster::neutron::dhcp':
        ha_agents         => $agents,
        admin_password    => $admin_password,
        admin_tenant_name => $admin_tenant_name,
        admin_username    => $admin_username,
        auth_url          => $auth_url
      }
    } elsif $ha_agents == 'slave' {
      Neutron::Agents::Dhcp {
        enabled         => false,
        manage_service  => false,
      }
    }
  }

  if 'l3' in $agents {
    class { '::neutron::agents::l3':
      debug                   => $debug,
      metadata_port           => $metadata_port,
      send_arp_for_ha         => $send_arp_for_ha,
      external_network_bridge => $external_network_bridge,
    }
    if $ha_agents  == 'primary' {
      # Yes, l3 is supposed to be a defined resource, this will become
      # necessary when we start supporting multiple external routers.
      cluster::neutron::l3{'default-l3':
        debug             => $debug,
        verbose           => $verbose,
        ha_agents         => $agents,
        admin_password    => $admin_password,
        admin_tenant_name => $admin_tenant_name,
        admin_username    => $admin_username,
        auth_url          => $auth_url
      }
    } elsif $ha_agents == 'slave' {
      Neutron::Agents::L3 {
        enabled         => false,
        manage_service  => false,
      }
    }
  }
}