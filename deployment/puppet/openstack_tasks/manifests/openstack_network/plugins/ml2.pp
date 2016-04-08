class openstack_tasks::openstack_network::plugins::ml2 {

  notice('MODULAR: openstack_network/plugins/ml2.pp')

  $use_neutron = hiera('use_neutron', false)

  if $use_neutron {
    # override neutron options
    $override_configuration = hiera_hash('configuration', {})
    override_resources { 'neutron_agent_ovs':
      data => $override_configuration['neutron_agent_ovs']
    } ~> Service['neutron-ovs-agent-service']
  }

  if $use_neutron {
    include ::neutron::params

    $node_name = hiera('node_name')
    $neutron_primary_controller_roles = hiera('neutron_primary_controller_roles', ['primary-controller'])
    $neutron_compute_roles            = hiera('neutron_compute_nodes', ['compute'])
    $primary_controller               = roles_include($neutron_primary_controller_roles)
    $compute                          = roles_include($neutron_compute_roles)

    $neutron_config = hiera_hash('neutron_config')
    $neutron_server_enable = pick($neutron_config['neutron_server_enable'], true)
    $neutron_nodes = hiera_hash('neutron_nodes')

    $dpdk_config = hiera_hash('dpdk', {})
    $enable_dpdk = pick($dpdk_config['enabled'], false)

    $management_vip         = hiera('management_vip')
    $service_endpoint       = hiera('service_endpoint', $management_vip)
    $ssl_hash               = hiera_hash('use_ssl', {})
    $internal_auth_protocol = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
    $internal_auth_address  = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [$service_endpoint])

    $auth_api_version   = 'v2.0'
    $identity_uri       = "${internal_auth_protocol}://${internal_auth_address}:5000"
    $auth_url           = "${identity_uri}/${auth_api_version}"
    $auth_password      = $neutron_config['keystone']['admin_password']
    $auth_user          = pick($neutron_config['keystone']['admin_user'], 'neutron')
    $auth_tenant        = pick($neutron_config['keystone']['admin_tenant'], 'services')
    $auth_region        = hiera('region', 'RegionOne')
    $auth_endpoint_type = 'internalURL'

    $network_scheme = hiera_hash('network_scheme', {})
    prepare_network_config($network_scheme)

    $neutron_advanced_config = hiera_hash('neutron_advanced_configuration', { })
    $l2_population     = try_get_value($neutron_advanced_config, 'neutron_l2_pop', false)
    $dvr               = try_get_value($neutron_advanced_config, 'neutron_dvr', false)
    $enable_qos        = pick($neutron_advanced_config['neutron_qos'], false)
    $segmentation_type = try_get_value($neutron_config, 'L2/segmentation_type')

    if $compute and ! $dvr {
      $do_floating = false
    } else {
      $do_floating = true
    }

    if $enable_qos {
      $extensions = ['qos']
    } else {
      $extensions = undef
    }

    $bridge_mappings = generate_bridge_mappings($neutron_config, $network_scheme, {
      'do_floating' => $do_floating,
      'do_tenant'   => true,
      'do_provider' => false
    })

    if $segmentation_type == 'vlan' {
      $net_role_property    = 'neutron/private'
      $iface                = get_network_role_property($net_role_property, 'phys_dev')
      $enable_tunneling = false
      $network_type = 'vlan'
      $tunnel_types = []
    } else {
      $net_role_property = 'neutron/mesh'
      $tunneling_ip      = get_network_role_property($net_role_property, 'ipaddr')
      $iface             = get_network_role_property($net_role_property, 'phys_dev')
      $physical_net_mtu  = pick(get_transformation_property('mtu', $iface[0]), '1500')

      if $segmentation_type == 'gre' {
        $mtu_offset = '42'
        $network_type = 'gre'
      } else {
        # vxlan is the default segmentation type for non-vlan cases
        $mtu_offset = '50'
        $network_type = 'vxlan'
      }
      $tunnel_types = [$network_type]

      $enable_tunneling = true
    }

    if $enable_dpdk and $compute {
      neutron_agent_ovs {
        'securitygroup/enable_security_group': value => false;
      }
      $firewall_driver          = 'neutron.agent.firewall.NoopFirewallDriver'
      $ovs_datapath_type        = 'netdev'
      $ovs_vhostuser_socket_dir = '/var/run/openvswitch'
    } else {
      neutron_agent_ovs {
        'securitygroup/enable_security_group': value  => true;
      }
      $firewall_driver          = 'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver'
      # Leave default values when passed to the class
      $ovs_datapath_type        = undef
      $ovs_vhostuser_socket_dir = undef
    }

    Neutron_agent_ovs<||> ~> Service['neutron-ovs-agent-service']

    class { '::neutron::agents::ml2::ovs':
      bridge_mappings            => $bridge_mappings,
      enable_tunneling           => $enable_tunneling,
      local_ip                   => $tunneling_ip,
      tunnel_types               => $tunnel_types,
      enable_distributed_routing => $dvr,
      l2_population              => $l2_population,
      arp_responder              => $l2_population,
      firewall_driver            => $firewall_driver,
      datapath_type              => $ovs_datapath_type,
      vhostuser_socket_dir       => $ovs_vhostuser_socket_dir,
      extensions                 => $extensions,
      manage_vswitch             => false,
      manage_service             => true,
      enabled                    => true,
    }

    if $node_name in keys($neutron_nodes) {
      if $neutron_server_enable {
        $service_ensure = 'running'
      } else {
        $service_ensure = 'stopped'
      }

      service { 'neutron-server':
        name       => $::neutron::params::server_service,
        enable     => $neutron_server_enable,
        ensure     => $service_ensure,
        hasstatus  => true,
        hasrestart => true,
        tag        => 'neutron-service',
      }

      exec { 'waiting-for-neutron-api':
        environment => [
          "OS_TENANT_NAME=${auth_tenant}",
          "OS_USERNAME=${auth_user}",
          "OS_PASSWORD=${auth_password}",
          "OS_AUTH_URL=${auth_url}",
          "OS_REGION_NAME=${auth_region}",
          "OS_ENDPOINT_TYPE=${auth_endpoint_type}",
        ],
        path        => '/usr/sbin:/usr/bin:/sbin:/bin',
        tries       => '30',
        try_sleep   => '4',
        command     => 'neutron net-list --http-timeout=4 2>&1 > /dev/null',
        provider    => 'shell',
        subscribe   => Service['neutron-server'],
        refreshonly => true,
      }

      $ha_agent = try_get_value($neutron_advanced_config, 'l2_agent_ha', true)
      if $ha_agent {
        #Exec<| title == 'waiting-for-neutron-api' |> ->
        class { '::cluster::neutron::ovs' :
          primary => $primary_controller,
        }
      }
    }

    # Stub for upstream neutron manifests
    package { 'neutron':
      name   => 'binutils',
      ensure => 'installed',
    }

  }

}
