notice('MODULAR: openstack-network-controller.pp')

$use_neutron                    = hiera('use_neutron', false)
$primary_controller             = hiera('primary_controller')
$access_hash                    = hiera('access', {})
$controllers                    = hiera('controllers')
$controller_internal_addresses  = nodes_to_hash($controllers,'name','internal_address')
$controller_nodes               = ipsort(values($controller_internal_addresses))
$rabbit_hash                    = hiera('rabbit_hash', {})
$internal_address               = hiera('internal_address')
$management_vip                 = hiera('management_vip')
$service_endpoint               = hiera('service_endpoint', $management_vip)
$nova_hash                      = hiera_hash('nova', {})
$ceilometer_hash                = hiera('ceilometer',{})
$network_scheme                 = hiera('network_scheme', {})

$internal_ssl_hash              = hiera('internal_ssl')
$nova_endpoint                  = hiera('nova_endpoint', $internal_ssl_hash['enable'] ? {
  true    => $internal_ssl_hash['hostname'],
  default => $management_vip,
})
$keystone_endpoint              = hiera('keystone_endpoint', $internal_ssl_hash['enable'] ? {
  true    => $internal_ssl_hash['hostname'],
  default => $service_endpoint,
})
$neutron_endpoint               = hiera('neutron_endpoint', $internal_ssl_hash['enable'] ? {
  true    => $internal_ssl_hash['hostname'],
  default => $management_vip,
})


$floating_hash = {}

# amqp settings
if hiera('amqp_nodes', false) {
  $amqp_nodes = hiera('amqp_nodes')
}
elsif $internal_address in $controller_nodes {
  # prefer local MQ broker if it exists on this node
  $amqp_nodes = concat(['127.0.0.1'], fqdn_rotate(delete($controller_nodes, $internal_address)))
} else {
  $amqp_nodes = fqdn_rotate($controller_nodes)
}
$amqp_port = hiera('amqp_port', '5673')
$amqp_hosts = inline_template("<%= @amqp_nodes.map {|x| x + ':' + @amqp_port}.join ',' %>")

class { 'l23network' :
  use_ovs => $use_neutron
}

if $use_neutron {
  $network_provider      = 'neutron'
  $novanetwork_params    = {}
  $neutron_config        = hiera_hash('quantum_settings')
  $neutron_metadata_proxy_secret = $neutron_config['metadata']['metadata_proxy_shared_secret']
  # Neutron Keystone settings
  $neutron_user_password = $neutron_config['keystone']['admin_password']
  $keystone_user         = pick($neutron_config['keystone']['admin_user'], 'neutron')
  $keystone_tenant       = pick($neutron_config['keystone']['admin_tenant'], 'services')
  # Neutron DB settings
  $neutron_db_password   = $neutron_config['database']['passwd']
  $neutron_db_user       = pick($neutron_config['database']['user'], 'neutron')
  $neutron_db_name       = pick($neutron_config['database']['name'], 'neutron')
  $neutron_db_host       = pick($neutron_config['database']['host'], $management_vip)
  $base_mac              = $neutron_config['L2']['base_mac']
} else {
  $network_provider   = 'nova'
  $floating_ips_range = hiera('floating_network_range')
  $neutron_config     = {}
  $novanetwork_params = hiera('novanetwork_parameters')
}

$keystone_admin_tenant = $access_hash[tenant]

$openstack_version = {
  'keystone'   => 'installed',
  'glance'     => 'installed',
  'horizon'    => 'installed',
  'nova'       => 'installed',
  'novncproxy' => 'installed',
  'cinder'     => 'installed',
}

if $network_provider == 'neutron' {
  $neutron_db_uri = "mysql://${neutron_db_user}:${neutron_db_password}@${neutron_db_host}/${neutron_db_name}?&read_timeout=60"
  $neutron_server = true

  # We need to restart nova-api after making changes via nova_config
  # so we need to declare the service and notify it
  include ::nova::params
  service { 'nova-api':
    ensure => 'running',
    name   => $::nova::params::api_service_name,
  }
  Nova_config<| |> ~> Service['nova-api']

  # FIXME(xarses) Nearly everything between here and the class
  # should be moved into osnaily or nailgun but will stay here
  # in the interum.
  $neutron_settings = $neutron_config
  $nets = $neutron_settings['predefined_networks']

  if $primary_controller {

    Service<| title == 'neutron-server' |> ->
      Openstack::Network::Create_network <||>

    Service<| title == 'neutron-server' |> ->
      Openstack::Network::Create_router <||>

    openstack::network::create_network{'net04':
      netdata => $nets['net04']
    } ->
    openstack::network::create_network{'net04_ext':
      netdata => $nets['net04_ext']
    } ->
    openstack::network::create_router{'router04':
      internal_network => 'net04',
      external_network => 'net04_ext',
      tenant_name      => $keystone_admin_tenant
    }

  }
  nova_config { 'DEFAULT/default_floating_pool': value => 'net04_ext' }
  $pnets = $neutron_settings['L2']['phys_nets']
  if $pnets['physnet1'] {
    $physnet1 = "physnet1:${pnets['physnet1']['bridge']}"
    notify{ $physnet1:}
  }
  if $pnets['physnet2'] {
    $physnet2 = "physnet2:${pnets['physnet2']['bridge']}"
    notify{ $physnet2:}
    if $pnets['physnet2']['vlan_range'] {
      $vlan_range = ["physnet2:${pnets['physnet2']['vlan_range']}"]
      $fallback = split($pnets['physnet2']['vlan_range'], ':')
      Openstack::Network::Create_network {
        tenant_name         => $keystone_admin_tenant,
        fallback_segment_id => $fallback[1]
      }
      notify{ $vlan_range:}
    }
  } else {
    $vlan_range = []
  }

  if $physnet1 and $physnet2 {
    $bridge_mappings = [$physnet1, $physnet2]
  } elsif $physnet1 {
    $bridge_mappings = [$physnet1]
  } elsif $physnet2 {
    $bridge_mappings = [$physnet2]
  } else {
    $bridge_mappings = []
  }

  # Required to use get_network_role_property
  prepare_network_config($network_scheme)

  if $neutron_settings['L2']['tunnel_id_ranges'] {
    # tunneling_mode
    $tunneling_ip = get_network_role_property('neutron/mesh', 'ipaddr')
    $iface = get_network_role_property('neutron/mesh', 'phys_dev')
    $net_mtu = get_transformation_property('mtu', $iface[0])
    if $net_mtu {
      $mtu_for_virt_network = $net_mtu - 42
    } else {
      $mtu_for_virt_network = 1458
    }
    $enable_tunneling = true
    $tunnel_id_ranges = [$neutron_settings['L2']['tunnel_id_ranges']]
    $alt_fallback = split($neutron_settings['L2']['tunnel_id_ranges'], ':')
    Openstack::Network::Create_network {
      tenant_name         => $keystone_admin_tenant,
      fallback_segment_id => $alt_fallback[0]
    }

  } else {
    # vlan_mode
    $iface = get_network_role_property('neutron/private', 'phys_dev')
    $mtu_for_virt_network = get_transformation_property('mtu', $iface[0])
    $enable_tunneling = false
    $tunneling_ip = false
    $tunnel_id_ranges = []
  }
  notify{ $tunnel_id_ranges:}

  if $neutron_settings['L2']['mechanism_drivers'] {
      $mechanism_drivers = split($neutron_settings['L2']['mechanism_drivers'], ',')
  } else {
      $mechanism_drivers = ['openvswitch']
  }

  if $neutron_settings['L2']['provider'] == 'ovs' {
    $core_plugin      = 'openvswitch'
    $service_plugins  = ['router', 'firewall', 'metering']
    $agent            = 'ovs'
  } else {
    $core_plugin      = 'neutron.plugins.ml2.plugin.Ml2Plugin'
    $service_plugins  = ['neutron.services.l3_router.l3_router_plugin.L3RouterPlugin','neutron.services.metering.metering_plugin.MeteringPlugin']
    $agent            = 'ml2-ovs'
  }

} else {
  $neutron_server = false
  $neutron_db_uri = undef

  case hiera('network_manager', undef) {
    'nova.network.manager.VlanManager': {
      Class['nova::network::vlan'] -> Nova::Manage::Network <||>
    }
    'nova.network.manager.FlatDHCPManager': {
      Class['nova::network::flatdhcp'] -> Nova::Manage::Network <||>
    }
    'nova.network.manager.FlatManager': {
      Class['nova::network::flat'] -> Nova::Manage::Network <||>
    }

  }

  # Stubs for nova::network
  file { '/etc/nova/nova.conf':
    ensure => 'present',
  }
}


class { 'openstack::network':
  network_provider    => $network_provider,
  agents              => [$agent, 'metadata', 'dhcp', 'l3'],
  ha_agents           => $neutron_config['ha_agents'] ? {
    default => $neutron_config['ha_agents'],
    undef   => $primary_controller ? {true => 'primary', default  => 'slave'},
  },
  verbose             => true,
  debug               => hiera('debug', true),
  use_syslog          => hiera('use_syslog', true),
  syslog_log_facility => hiera('syslog_log_facility_neutron', 'LOG_LOCAL4'),

  neutron_server      => $neutron_server,
  neutron_db_uri      => $neutron_db_uri,
  nova_neutron        => true,
  base_mac            => $base_mac,
  core_plugin         => $core_plugin,
  service_plugins     => $service_plugins,
  net_mtu             => $mtu_for_virt_network,

  #ovs
  mechanism_drivers   => $mechanism_drivers,
  local_ip            => $tunneling_ip,
  bridge_mappings     => $bridge_mappings,
  network_vlan_ranges => $vlan_range,
  enable_tunneling    => $enable_tunneling,
  tunnel_id_ranges    => $tunnel_id_ranges,

  #Queue settings
  queue_provider  => hiera('queue_provider', 'rabbitmq'),
  amqp_hosts      => [$amqp_hosts],
  amqp_user       => $rabbit_hash['user'],
  amqp_password   => $rabbit_hash['password'],

  # keystone
  admin_password    => $neutron_user_password,
  auth_host         => $keystone_endpoint,
  auth_url          => "http://${keystone_endpoint}:35357/v2.0",
  neutron_url       => $internal_ssl_hash['enable'] ? {
    true    => "https://${neutron_endpoint}:9696",
    default => "http://${neutron_endpoint}:9696",
  },
  admin_tenant_name => $keystone_tenant,
  admin_username    => $keystone_user,

  # Ceilometer notifications
  ceilometer => $ceilometer_hash['enabled'],

  #metadata
  shared_secret   => $neutron_metadata_proxy_secret,
  metadata_ip     => $nova_endpoint,

  #nova settings
  private_interface      => $use_neutron ? { true=>false, default=>hiera('private_int', undef)},
  public_interface       => hiera('public_int', undef),
  fixed_range            => $use_neutron ? { true =>false, default =>hiera('fixed_network_range', undef)},
  floating_range         => $use_neutron ? { true =>$floating_hash, default  =>false},
  network_manager        => hiera('network_manager', undef),
  network_config         => hiera('network_config', {}),
  create_networks        => $primary_controller,
  num_networks           => hiera('num_networks', undef),
  network_size           => hiera('network_size', undef),
  nameservers            => hiera('dns_nameservers', undef),
  enable_nova_net        => false,  # just setup networks, but don't start nova-network service on controllers
  nova_admin_username    => $nova_hash['user'],
  nova_admin_tenant_name => $nova_hash['tenant'],
  nova_admin_password    => $nova_hash['user_password'],
  nova_url               => $internal_ssl_hash['enable'] ? {
    true    => "https://${nova_endpoint}:8774/v2",
    default => "http://${nova_endpoint}:8774/v2",
  }
}
