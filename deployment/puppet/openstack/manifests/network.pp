# == Class: openstack::network
#
# Entry points for OpenStack networking services
#
# === Parameters
#
# [*dvr*]
#   (optional) Enabled or not Neutron DVR (distributed virtual router)
#   Defaults to false
#
# [*l2_population*]
#   (optional) Enabled or not ml2 plugin's l2population mechanism driver.
#   Defaults to false
#
# [*use_stderr*]
#   (optional) Rather or not service should send output to stderr.
#   Defaults to true
#
class openstack::network (
  # asdf = {} #Trick to color editor
  $network_provider = 'neutron',
  $agents           = ['ml2-ovs'], # ml2-ovs metadata dhcp l3
  $ha_agents        = false,

  $verbose             = false,
  $debug               = false,
  $use_syslog          = false,
  $use_stderr          = true,
  $syslog_log_facility = 'LOG_USER',

  # ovs
  $enable_tunneling     = false,
  $tunnel_bridge        = 'br-tun',
  $tunnel_id_ranges     = ['20:100'],
  $integration_bridge   = 'br-int',
  $bridge_mappings      = [],
  $network_vlan_ranges  = ['physnet2:1000:2999'],
  $local_ip             = false,
  $tunnel_types         = [],

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
  $metadata_ip       = '127.0.0.1',
  $isolated_metadata = false,

  # dhcp-agent
  $resync_interval  = 30,

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
  $identity_uri      = 'http://127.0.0.1:35357',
  $auth_url          = 'http://127.0.0.1:5000',
  $region            = 'RegionOne',
  $neutron_url       = 'http://127.0.0.1:9696',

  # Ceilometer notifications
  $ceilometer = false,

  # Nova settings
  $private_interface,
  $public_interface,
  $fixed_range,
  $floating_range         = false,
  $network_manager        = 'nova.network.manager.FlatDHCPManager',
  $network_config         = {},
  $create_networks        = true,
  $num_networks           = 1,
  $network_size           = 255,
  $nameservers            = undef,
  $enable_nova_net        = false,
  $integration_bridge     = undef, #'br-int'
  $nova_neutron           = false, #Enable to run nova::network::neutron, usefull for computes and controllers, but not routers
  $nova_admin_username    = 'nova',
  $nova_admin_tenant_name = 'services',
  $nova_admin_password    = 'secret',
  $nova_url               = 'http://127.0.0.1:8774/v2',

  # Neutron
  $neutron_server        = false,
  $neutron_db_uri        = undef,
  $bind_host             = '0.0.0.0',
  $base_mac              = 'fa:16:3e:00:00:00',
  $core_plugin           = 'neutron.plugins.ml2.plugin.Ml2Plugin',
  $service_plugins       = ['neutron.services.l3_router.l3_router_plugin.L3RouterPlugin'],
  $dvr                   = false,
  $l2_population         = false,
  $neutron_server_enable = true,
  $network_device_mtu    = undef,
  $service_workers       = $::processorcount,
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

  # All nodes with network functions should have these thresholds
  # to avoid "Neighbour table overflow" problem
  sysctl::value { 'net.ipv4.neigh.default.gc_thresh1':
    value => '1024'
  }
  sysctl::value { 'net.ipv4.neigh.default.gc_thresh2':
    value => '2048'
  }
  sysctl::value { 'net.ipv4.neigh.default.gc_thresh3':
    value => '4096'
  }

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
        use_stderr              => $use_stderr,
        log_facility            => $syslog_log_facility,
        bind_host               => $bind_host,
        base_mac                => $base_mac,
        core_plugin             => $core_plugin,
        service_plugins         => $neutron_server ? {false => undef, default => $service_plugins},
        allow_overlapping_ips   => true,
        mac_generation_retries  => 32,
        dhcp_lease_duration     => 600,
        dhcp_agents_per_network => 2,
        report_interval         => 10,
        rabbit_user             => $amqp_user,
        rabbit_host             => $amqp_host,
        rabbit_hosts            => $amqp_hosts,
        rabbit_port             => $amqp_port,
        rabbit_password         => $amqp_password,
        network_device_mtu      => $network_device_mtu,
      }

      if $nova_neutron {
        class {'nova::network::neutron':
          neutron_admin_password    => $admin_password,
          neutron_admin_tenant_name => $admin_tenant_name,
          neutron_region_name       => $region,
          neutron_admin_username    => $admin_username,
          neutron_admin_auth_url    => "${identity_uri}/v2.0",
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

          auth_password => $admin_password,
          auth_tenant   => $admin_tenant_name,
          auth_region   => $region,
          auth_user     => $admin_username,
          auth_uri      => $auth_url,
          identity_uri  => $identity_uri,

          database_retry_interval => 2,
          database_connection     => $neutron_db_uri,
          database_max_retries    => -1,

          agent_down_time => 30,
          allow_automatic_l3agent_failover => true,

          api_workers => $service_workers,
          rpc_workers => $service_workers,

          router_distributed => $dvr,
          enabled     => $neutron_server_enable,
        }

        tweaks::ubuntu_service_override { "$::neutron::params::server_service":
          package_name => $::neutron::params::server_package ? {
              false   => $::neutron::params::package_name,
              default => $::neutron::params::server_package
          }
        }

        class { 'neutron::server::notifications':
          nova_url                => $nova_url,
          nova_admin_auth_url     => "${identity_uri}/v2.0",
          nova_admin_username     => $nova_admin_username,
          nova_admin_tenant_name  => $nova_admin_tenant_name,
          nova_admin_password     => $nova_admin_password,
          nova_region_name        => $region,
        }

        # In Juno Neutron API ready for answer not yet when server starts.
        exec {'waiting-for-neutron-api':
          environment => [
            "OS_TENANT_NAME=${admin_tenant_name}",
            "OS_USERNAME=${admin_username}",
            "OS_PASSWORD=${admin_password}",
            "OS_AUTH_URL=${identity_uri}/v2.0",
            "OS_REGION_NAME=${region}",
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

      if $dvr {
        $agent_mode = $neutron_server ? {
          true  => 'dvr_snat',
          false => 'dvr',
        }
      } else {
        $agent_mode = 'legacy'
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
          debug     => $debug,

          admin_password    => $admin_password,
          admin_tenant_name => $admin_tenant_name,
          admin_username    => $admin_username,
          auth_url          => "${identity_uri}/v2.0",
          auth_region       => $region,

          #ovs
          tunnel_bridge         => $tunnel_bridge,
          enable_tunneling      => $enable_tunneling,
          integration_bridge    => $integration_bridge,
          tunnel_id_ranges      => $tunnel_id_ranges,
          tenant_network_types  => $tenant_network_types,
          network_vlan_ranges   => $network_vlan_ranges,
          bridge_mappings       => $bridge_mappings,
          local_ip              => $local_ip,
          tunnel_types          => $tunnel_types,
          l2_population         => $l2_population,

          #ML2 only
          type_drivers          => $type_drivers,
          mechanism_drivers     => $mechanism_drivers,
          flat_networks         => $flat_networks,
          vxlan_group           => $vxlan_group,
          vni_ranges            => $vni_ranges,

          #metadata-agent
          shared_secret     => $shared_secret,
          metadata_ip       => $metadata_ip,
          isolated_metadata => $isolated_metadata,

          #dhcp-agent
          resync_interval => $resync_interval,
          net_mtu         => $net_mtu,

          #l3-agent
          metadata_port           => $metadata_port,
          send_arp_for_ha         => $send_arp_for_ha,
          external_network_bridge => $floating_bridge,
          agent_mode              => $agent_mode,
        }
      }
    } # End case neutron
  } # End Case
}
