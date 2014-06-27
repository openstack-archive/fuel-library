# Entry points for OpenStack networking services
# not a doc string

class openstack::network (
  # asdf = {} #Trick to color editor
  $network_provider = 'neutron',
  $agents           = ['ml2-ovs'], # ovs, ml2-ovs metadata dhcp l3
  $ha_agents        = false,

  $public_address,
  $internal_address,
  $admin_address,

  $verbose    = false,
  $debug      = false,
  $use_syslog = flase,

  $syslog_log_facility = 'LOG_USER',

  #ovs
  $tunnel_bridge = 'br-tun',
  $enable_tunneling = false,
  $integration_bridge = 'br-int',
  $bridge_mappings = [],
  $local_ip = false,

  #ML2 settings
  $type_drivers          = ['flat', 'vlan', 'gre', 'vxlan'],
  $tenant_network_types  = ['flat', 'vlan', 'gre', 'vxlan'],
  $mechanism_drivers     = ['openvswitch', 'linuxbridge'],
  $flat_networks         = ['*'],
  $network_vlan_ranges   = ['physnet2:1000:2999'],
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
  $metadata_port = 8775,
  $send_arp_for_ha = 8,
  $external_network_bridge = 'br-ex',

  # amqp
  $queue_provider = 'rabbitmq',
  $amqp_user      = 'guest',
  $amqp_host      = ['localhost'],
  $amqp_hosts     = false,
  $amqp_port      = '5672',
  $amqp_password  = 'password',

  # keystone
  $admin_password    = 'asdf123',
  $admin_tenant_name = 'services',
  $admin_username    = 'neutron',
  $auth_host         = 'localhost',
  $auth_port         = '35357',
  $auth_protocol     = 'http',
  $auth_url          = 'http://127.0.0.1:5000/v2.0',
  $region            = 'RegionOne',
  $api_url           = $quantum_config['server']['api_url'],

  # Nova settings
  $private_interface,
  $public_interface,
  $fixed_range,
  $floating_range   = false,
  $network_manager  = 'nova.network.manager.FlatDHCPManager',
  $network_config   = {},
  $create_networks  = true,
  $num_networks     = 1,
  $network_size     = 255,
  $nameservers      = undef,
  $enable_nova_net  = false,
  $integration_bridge  = undef, #'br-int'
  $nova_neutron     = false, #Enable to run nova::network::neutron
  $nova_admin_password = 'secret',
  $nova_url         = 'http://127.0.0.1:8774/v2',

  # Neutron
  $neutron_server = false,
  $neutron_db_uri = undef,
  $base_mac       = 'fa:16:3e:00:00:00',
  $core_plugin    = 'neutron.plugins.ml2.plugin.Ml2Plugin', #'openvswitch' or 'ml2'
  $service_plugins= ['neutron.services.l3_router.l3_router_plugin.L3RouterPlugin'],

  # Precreate networks and routers
  $precreate = {}
  )
{
#  if ! $bridge_mappings {
#    $physnet1 = "physnet1:${external_network_bridge}"
#    if "vlan" in $type_drivers {
#      $physnet2 = 'physnet2:br-prv'
#    }
#    $real_bridge_mappings = [$physnet1, $physnet2]
#  }
  case $network_provider {
    'nova': {
      class { 'nova::network':
        ensure_package    => $::openstack_version['nova'],
        private_interface => $private_interface,
        public_interface  => $public_interface,
        fixed_range       => $fixed_range,
        floating_range    => $floating_range,
        network_manager   => $network_manager,
        config_overrides  => $network_config,
        create_networks   => $create_networks,
        num_networks      => $num_networks,
        network_size      => $network_size,
        nameservers       => $nameservers,
        enabled           => $enable_nova_net,
        install_service   => $enable_nova_net,
      }
    } # End case nova
    'neutron': {
      class {'::neutron':
        #verbose                 => $verbose,
        debug                   => $debug,
        use_syslog              => $use_syslog,
        log_facility            => $syslog_log_facility,
        base_mac                => $base_mac,
        core_plugin             => $core_plugin,
        service_plugins          => $service_plugins,
        allow_overlapping_ips   => true,
        mac_generation_retries  => 32,
        dhcp_lease_duration     => 120,
        dhcp_agents_per_network => 1,
        report_interval         => 5,
        rabbit_user             => $amqp_user,
        rabbit_host             => $amqp_host,
        rabbit_hosts            => $amqp_hosts,
        rabbit_port             => $amqp_port,
        rabbit_password         => $amqp_password

      }
      if $nova_neutron {
        class {'nova::network::neutron':
          neutron_admin_password    => $admin_password,
          neutron_admin_tenant_name => $admin_tenant_name,
          neutron_region_name       => $region,
          neutron_admin_username    => $admin_username,
          neutron_admin_auth_url    => $auth_url,
          neutron_url               => $api_url,
          neutron_ovs_bridge        => $integration_bridge
        }
      }

      if $neutron_server {
        if ! $neutron_db_uri {
          fail("You must provide a neutron_db_uri for neutron servers")
        }
        class { '::neutron::server':
          sync_db =>  true,

          auth_host     => $auth_host,
          auth_port     => $auth_port,
          auth_protocol => $auth_protocol,
          auth_password => $admin_password,
          auth_tenant   => $admin_tenant_name,
          auth_user     => $admin_username,
          auth_uri      => $auth_url,

          database_retry_interval => 2,
          database_connection     => $neutron_db_uri,
          database_max_retries    => -1,

          agent_down_time => 15
        }

        class { 'neutron::server::notifications':
          nova_url                => $nova_url,
          nova_admin_auth_url     => $auth_url,
          nova_admin_username     => 'nova', # Default
          nova_admin_tenant_name  => 'services', # Default
          nova_admin_password     => $nova_admin_password,
        }

      }

      if $agents {
        class {'openstack::network::neutron_agents':
          agents    => $agents,
          ha_agents => $ha_agents,
          verbose   => $verbose,
          debug     => $debug,

          admin_password    => $admin_password,
          admin_tenant_name => $admin_tenant_name,
          admin_username    => $admin_username,
          auth_url          => $auth_url,

          #ovs
          tunnel_bridge         => $tunnel_bridge,
          enable_tunneling      => $enable_tunneling,
          integration_bridge    => $integration_bridge,
          tunnel_id_ranges      => $tunnel_id_ranges,
          tenant_network_types  => $tenant_network_types,
          network_vlan_ranges   => $network_vlan_ranges,
          bridge_mappings       => $bridge_mappings,
          local_ip              => $local_ip,

          #ML2 only
          type_drivers          => $type_drivers,
          mechanism_drivers     => $mechanism_drivers,
          flat_networks         => $flat_networks,
          vxlan_group           => $vxlan_group,
          vni_ranges            => $vni_ranges,

          #metadata-agent
          shared_secret => $shared_secret,
          metadata_ip   => $metadata_ip,

          #dhcp-agent
          resync_interval => $resync_interval,
          use_namespaces  => $use_namespaces,

          #l3-agent
          metadata_port           => $metadata_port,
          send_arp_for_ha         => $send_arp_for_ha,
          external_network_bridge => $external_network_bridge,
        }

      }
    } # End case neutron
  } # End Case
}
