# Entry points for OpenStack networking services
# not a doc string

class openstack::network (
  # asdf = {} #Trick to color editor
  $network_provider = 'neutron',
  $agents           = ['ml2-ovs'], # ovs, ml2-ovs metadata dhcp l3
  $ha_agents        = false,

  $verbose             = false,
  $debug               = false,
  $use_syslog          = flase,
  $syslog_log_facility = 'LOG_USER',

  # ovs
  $enable_tunneling     = false,
  $tunnel_bridge        = 'br-tun',
  $tunnel_id_ranges     = ['20:100'],
  $integration_bridge   = 'br-int',
  $bridge_mappings      = [],
  $network_vlan_ranges  = ['physnet2:1000:2999'],
  $local_ip             = false,

  # dhcp
  $net_mtu = undef,

  # ML2 settings
  $type_drivers          = ['local', 'flat', 'vlan', 'gre', 'vxlan'],
  $tenant_network_types  = ['flat', 'vlan', 'gre'],
  $mechanism_drivers     = ['openvswitch', 'linuxbridge'],
  $flat_networks         = ['*'],
  $vxlan_group           = '224.0.0.1',
  $vni_ranges            = ['10:10000'],

  # metadata-agent
  $shared_secret,
  $metadata_ip      = '127.0.0.1',

  # dhcp-agent
  $resync_interval  = 30,
  $use_namespaces   = true,

  # l3-agent
  $metadata_port            = 8775,
  $send_arp_for_ha          = 8,
  $floating_bridge          = 'br-floating',

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
  $neutron_url       = 'http://127.0.0.1:9696',

  # Ceilometer notifications
  $ceilometer = false,

  # Nova settings
  $private_interface,
  $public_interface,
  $fixed_range,
  $floating_range       = false,
  $network_manager      = 'nova.network.manager.FlatDHCPManager',
  $network_config       = {},
  $create_networks      = true,
  $num_networks         = 1,
  $network_size         = 255,
  $nameservers          = undef,
  $enable_nova_net      = false,
  $integration_bridge   = undef, #'br-int'
  $nova_neutron         = false, #Enable to run nova::network::neutron, usefull for computes and controllers, but not routers
  $nova_admin_password  = 'secret',
  $nova_url             = 'http://127.0.0.1:8774/v2',

  # Neutron
  $neutron_server   = false,
  $neutron_db_uri   = undef,
  $base_mac         = 'fa:16:3e:00:00:00',
  $core_plugin      = 'neutron.plugins.ml2.plugin.Ml2Plugin',
  $service_plugins  = ['neutron.services.l3_router.l3_router_plugin.L3RouterPlugin'],
  )
{

  # All nodes with network functions should have net forwarding.
  # Its a requirement for network namespaces to function.
  if !defined(Sysctl::Value['net.ipv4.ip_forward']) {
    sysctl::value { 'net.ipv4.ip_forward':
      value => '1'
    }
  } else {
    Sysctl::Value<| name == 'net.ipv4.ip_forward' |> {
      value => '1'
    }
  }
  Sysctl::Value<| name == 'net.ipv4.ip_forward' |> -> Nova_config<||>

  case $network_provider {
    'nova': {
      class { 'nova::network':
        ensure_package    => $::openstack_version['nova'],
        private_interface => $private_interface,
        public_interface  => $public_interface,
        fixed_range       => $fixed_range,
        floating_range    => $floating_range,
        network_manager   => $network_manager,
        config_overrides  => $network_config,  # $config_overrides,
        create_networks   => $create_networks,
        num_networks      => $num_networks,
        network_size      => $network_size,
        nameservers       => $nameservers,
        enabled           => $enable_nova_net,
        install_service   => $enable_nova_net,
      }
      #NOTE(aglarendil): lp/1381164
      nova_config {'DEFAULT/force_snat_range': value => '0.0.0.0/0' }

    } # End case nova

    'neutron': {

      Sysctl::Value<| name == 'net.ipv4.ip_forward' |> -> Neutron_config<||>
      class {'::neutron':
        verbose                 => $verbose,
        debug                   => $debug,
        use_syslog              => $use_syslog,
        log_facility            => $syslog_log_facility,
        base_mac                => $base_mac,
        core_plugin             => $core_plugin,
        service_plugins         => $neutron_server ? {false => undef, default => $service_plugins},
        allow_overlapping_ips   => true,
        mac_generation_retries  => 32,
        dhcp_lease_duration     => 600,
        dhcp_agents_per_network => 2,
        report_interval         => 5,
        rabbit_user             => $amqp_user,
        rabbit_host             => $amqp_host,
        rabbit_hosts            => $amqp_hosts,
        rabbit_port             => $amqp_port,
        rabbit_password         => $amqp_password,
        kombu_reconnect_delay   => '5.0',
        network_device_mtu      => $net_mtu,
      }

      if $nova_neutron {
        class {'nova::network::neutron':
          neutron_admin_password    => $admin_password,
          neutron_admin_tenant_name => $admin_tenant_name,
          neutron_region_name       => $region,
          neutron_admin_username    => $admin_username,
          neutron_admin_auth_url    => $auth_url,
          neutron_url               => $neutron_url,
          neutron_ovs_bridge        => $integration_bridge
        }
      }

      if $neutron_server {
        if ! $neutron_db_uri {
          fail("You must provide a neutron_db_uri for neutron servers")
        }
        # Calculating $sync_db in class ::neutron::server:
        # $ha_agents for "simple" configurations is false and database should be synced;
        # $ha_agents for "HA" configurations may be 'primary' or 'slave'. Database should
        # be synced only on primary controller.
        class { '::neutron::server':
          sync_db       =>  $ha_agents ? {'primary' => true, false => true, default => false},

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

          agent_down_time => 15,

          api_workers => min($::processorcount + 0, 50 + 0),
          rpc_workers => min($::processorcount + 0, 50 + 0),
        }
        tweaks::ubuntu_service_override { "$::neutron::params::server_service":
          package_name => $::neutron::params::server_package ? {
              false   => $::neutron::params::package_name,
              default => $::neutron::params::server_package
          }
        }

        class { 'neutron::server::notifications':
          nova_url                => $nova_url,
          nova_admin_auth_url     => $auth_url,
          nova_admin_username     => 'nova', # Default
          nova_admin_tenant_name  => 'services', # Default
          nova_admin_password     => $nova_admin_password,
        }

        # In Juno Neutron API ready for answer not yet when server starts.
        exec {'waiting-for-neutron-api':
          environment => [
            "OS_TENANT_NAME=${admin_tenant_name}",
            "OS_USERNAME=${admin_username}",
            "OS_PASSWORD=${admin_password}",
            "OS_AUTH_URL=${auth_url}",
            'OS_ENDPOINT_TYPE=internalURL',
          ],
          tries     => 30,
          try_sleep => 4,
          command   => "bash -c \"neutron net-list --http-timeout=4 \" 2>&1 > /dev/null",
          path      => '/usr/sbin:/usr/bin:/sbin:/bin',
        }

        Service['neutron-server'] -> Exec<| title == 'waiting-for-neutron-api' |>
        Exec<| title == 'waiting-for-neutron-api' |> -> Neutron_network<||>
        Exec<| title == 'waiting-for-neutron-api' |> -> Neutron_subnet<||>
        Exec<| title == 'waiting-for-neutron-api' |> -> Neutron_router<||>
      }

      if $use_syslog {
        neutron_config { 'DEFAULT/use_syslog_rfc_format': value => true; }
      }

      if $ceilometer {
        neutron_config { 'DEFAULT/notification_driver': value => 'messaging' }
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
          net_mtu         => $net_mtu,

          #l3-agent
          metadata_port           => $metadata_port,
          send_arp_for_ha         => $send_arp_for_ha,
          external_network_bridge => $floating_bridge,
        }
      }
    } # End case neutron
  } # End Case
}
