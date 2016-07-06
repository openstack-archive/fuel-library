notice('MODULAR: openstack-network-controller.pp')

$use_neutron                    = hiera('use_neutron', false)
$primary_controller             = hiera('primary_controller')
$access_hash                    = hiera('access', {})
$rabbit_hash                    = hiera_hash('rabbit_hash', {})
$management_vip                 = hiera('management_vip')
$service_endpoint               = hiera('service_endpoint')
$nova_hash                      = hiera_hash('nova', {})
$ceilometer_hash                = hiera('ceilometer',{})
$network_scheme                 = hiera('network_scheme', {})
$nova_endpoint                  = hiera('nova_endpoint', $management_vip)
$neutron_endpoint               = hiera('neutron_endpoint', $management_vip)
$region                         = hiera('region', 'RegionOne')
$memcached_servers              = hiera('memcached_servers')

$floating_hash = {}

class { 'l23network' :
  use_ovs => $use_neutron
}

if $use_neutron {
  $network_provider              = 'neutron'
  $novanetwork_params            = {}
  $neutron_config                = hiera_hash('quantum_settings')
  $neutron_advanced_config       = hiera_hash('neutron_advanced_configuration', {})
  $neutron_metadata_proxy_secret = $neutron_config['metadata']['metadata_proxy_shared_secret']
  #todo(sv): default value set to false as soon as Nailgun/UI part be ready
  $isolated_metadata     = pick($neutron_config['metadata']['isolated_metadata'], true)
  $neutron_agents        = pick($neutron_config['neutron_agents'], ['metadata', 'dhcp', 'l3'])
  $neutron_server_enable = pick($neutron_config['neutron_server_enable'], true)
  $conf_nova             = pick($neutron_config['conf_nova'], true)
  $service_workers       = pick($neutron_config['workers'],
                                min(max($::processorcount, 2), 16))

  # Neutron Keystone settings
  $neutron_user_password = $neutron_config['keystone']['admin_password']
  $keystone_user         = pick($neutron_config['keystone']['admin_user'], 'neutron')
  $keystone_tenant       = pick($neutron_config['keystone']['admin_tenant'], 'services')
  # Neutron DB settings
  $neutron_db_password   = $neutron_config['database']['passwd']
  $neutron_db_user       = pick($neutron_config['database']['user'], 'neutron')
  $neutron_db_name       = pick($neutron_config['database']['name'], 'neutron')
  $neutron_db_host       = pick($neutron_config['database']['host'], hiera('database_vip'))
  $base_mac              = $neutron_config['L2']['base_mac']
  neutron_config {
    'keystone_authtoken/memcached_servers' : value => join(any2array($memcached_servers), ',');
  }
} else {
  $network_provider   = 'nova'
  $floating_ips_range = hiera('floating_network_range')
  $neutron_config     = {}
  $novanetwork_params = hiera('novanetwork_parameters')
  $isolated_metadata  = false
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
  # Required to use get_network_role_property
  prepare_network_config($network_scheme)

  $neutron_db_uri = "mysql://${neutron_db_user}:${neutron_db_password}@${neutron_db_host}/${neutron_db_name}?&read_timeout=60"
  $neutron_server = true
  $neutron_local_address_for_bind = get_network_role_property('neutron/api', 'ipaddr')
  $floating_bridge = get_network_role_property('neutron/floating', 'interface')
  $segmentation_type = $neutron_config['L2']['segmentation_type']

  if $segmentation_type != 'vlan' {
    # tunneling_mode
    $net_role_property = 'neutron/mesh'
    $tunneling_ip = get_network_role_property($net_role_property, 'ipaddr')
    $iface = get_network_role_property($net_role_property, 'phys_dev')
    $phys_net_mtu = get_transformation_property('mtu', $iface[0])
    $enable_tunneling = true
    if $segmentation_type =='gre' {
      $network_type = 'gre'
      $mtu_offset = 42
    } else {
      $network_type = 'vxlan'
      $mtu_offset = 50
    }
    if $phys_net_mtu {
      $overlay_net_mtu = $phys_net_mtu - $mtu_offset
    } else {
      $overlay_net_mtu = 1500 - $mtu_offset
    }
    $tunnel_types = [$network_type]
    $tenant_network_types  = ['flat', 'vlan', $network_type]
    $tunnel_id_ranges = [$neutron_config['L2']['tunnel_id_ranges']]
    $alt_fallback = split($neutron_config['L2']['tunnel_id_ranges'], ':')
    Openstack::Network::Create_network {
      tenant_name         => $keystone_admin_tenant,
      fallback_segment_id => $alt_fallback[0]
    }

  } else {
    # vlan_mode
    $net_role_property = 'neutron/private'
    $iface = get_network_role_property($net_role_property, 'phys_dev')
    $mtu_for_virt_network = get_transformation_property('mtu', $iface[0])
    $overlay_net_mtu = pick($mtu_for_virt_network, 1500)
    $enable_tunneling = false
    $network_type = 'vlan'
    $tenant_network_types  = ['flat', 'vlan']
    $tunnel_types = []
    $tunneling_ip = false
    $tunnel_id_ranges = []
  }

  # We need to restart nova-api after making changes via nova_config
  # so we need to declare the service and notify it
  if ($conf_nova){
    include ::nova::params
    service { 'nova-api':
      ensure => 'running',
      name   => $::nova::params::api_service_name,
    }

    nova_config { 'DEFAULT/default_floating_pool': value => 'net04_ext' }
    Nova_config<| |> ~> Service['nova-api']
  }

  # FIXME(xarses) Nearly everything between here and the class
  # should be moved into osnaily or nailgun but will stay here
  # in the interum.
  $nets = $neutron_config['predefined_networks']

  if $primary_controller and $nets and !empty($nets) {

    Service<| title == 'neutron-server' |> ->
      Openstack::Network::Create_network <||>

    Service<| title == 'neutron-server' |> ->
      Openstack::Network::Create_router <||>

    openstack::network::create_network{'net04':
      netdata           => $nets['net04'],
      segmentation_type => $network_type,
    } ->
    openstack::network::create_network{'net04_ext':
      netdata           => $nets['net04_ext'],
      segmentation_type => 'local',
    } ->
    openstack::network::create_router{'router04':
      internal_network => 'net04',
      external_network => 'net04_ext',
      tenant_name      => $keystone_admin_tenant
    }

  }

  $pnets = $neutron_config['L2']['phys_nets']
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

  if $neutron_config['L2']['mechanism_drivers'] {
      $mechanism_drivers = split($neutron_config['L2']['mechanism_drivers'], ',')
  } else {
      $mechanism_drivers = ['openvswitch', 'l2population']
  }

  $core_plugin      = 'neutron.plugins.ml2.plugin.Ml2Plugin'
  $service_plugins  = ['neutron.services.l3_router.l3_router_plugin.L3RouterPlugin','neutron.services.metering.metering_plugin.MeteringPlugin']
  $agent            = 'ml2-ovs'


  $dvr           = pick($neutron_advanced_config['neutron_dvr'], false)
  $l2_population = pick($neutron_advanced_config['neutron_l2_pop'], false)

} else {
  $neutron_server = false
  $neutron_db_uri = undef
  $neutron_local_address_for_bind = undef
  $floating_bridge = undef

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
  agents              => flatten([$agent, $neutron_agents]),
  ha_agents           => $neutron_config['ha_agents'] ? {
    default => $neutron_config['ha_agents'],
    undef   => $primary_controller ? {true => 'primary', default  => 'slave'},
  },
  verbose             => true,
  debug               => hiera('debug', true),
  use_syslog          => hiera('use_syslog', true),
  use_stderr          => hiera('use_stderr', false),
  syslog_log_facility => hiera('syslog_log_facility_neutron', 'LOG_LOCAL4'),

  neutron_server        => $neutron_server,
  neutron_server_enable => $neutron_server_enable,
  neutron_db_uri        => $neutron_db_uri,
  nova_neutron          => $conf_nova,
  base_mac              => $base_mac,
  core_plugin           => $core_plugin,
  service_plugins       => $service_plugins,
  net_mtu               => pick($phys_net_mtu, 1500),
  network_device_mtu    => $overlay_net_mtu,
  bind_host             => $neutron_local_address_for_bind,
  dvr                   => $dvr,
  l2_population         => $l2_population,
  service_workers       => $service_workers,

  #ovs
  mechanism_drivers    => $mechanism_drivers,
  local_ip             => $tunneling_ip,
  bridge_mappings      => $bridge_mappings,
  network_vlan_ranges  => $vlan_range,
  enable_tunneling     => $enable_tunneling,
  tunnel_id_ranges     => $tunnel_id_ranges,
  vni_ranges           => $tunnel_id_ranges,
  tunnel_types         => $tunnel_types,
  tenant_network_types => $tenant_network_types,

  floating_bridge      => $floating_bridge,

  #Queue settings
  queue_provider  => hiera('queue_provider', 'rabbitmq'),
  amqp_hosts      => split(hiera('amqp_hosts', ''), ','),

  amqp_user       => $rabbit_hash['user'],
  amqp_password   => $rabbit_hash['password'],

  # keystone
  admin_password    => $neutron_user_password,
  auth_url          => "http://${service_endpoint}:5000",
  identity_uri      => "http://${service_endpoint}:35357",
  neutron_url       => "http://${neutron_endpoint}:9696",
  admin_tenant_name => $keystone_tenant,
  admin_username    => $keystone_user,
  region            => $region,

  # Ceilometer notifications
  ceilometer => $ceilometer_hash['enabled'],

  #metadata
  shared_secret     => $neutron_metadata_proxy_secret,
  metadata_ip       => $nova_endpoint,
  isolated_metadata => $isolated_metadata,

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
  nova_url               => "http://${nova_endpoint}:8774/v2",
}
