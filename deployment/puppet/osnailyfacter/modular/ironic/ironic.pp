notice('MODULAR: ironic.pp')

$nova_hash                  = hiera('nova')
$public_ip                  = hiera('public_vip')
$internal_address               = hiera('internal_address')
$debug                      = hiera('debug', false)
$verbose                    = hiera('verbose', true)
$rabbit_hash                = hiera('rabbit_hash')
$amqp_hosts                 = hiera('amqp_hosts')
$nodes_hash                 = hiera('nodes')
$roles                      = node_roles($nodes_hash, hiera('uid'))
$nova_report_interval       = hiera('nova_report_interval')
$nova_service_down_time     = hiera('nova_service_down_time')
$controllers                    = hiera('controllers')
$controller_internal_addresses  = nodes_to_hash($controllers,'name','internal_address')
$controller_nodes               = ipsort(values($controller_internal_addresses))
$neutron_config        = hiera('quantum_settings')
$memcached_servers =  suffix($controller_nodes, inline_template(":11211"))
$neutron_net = $neutron_config['predefined_networks']['baremetal']

$ironic_hash  = hiera_hash('ironic', {})
$mysql_hash     = hiera_hash('mysql', {})
$management_vip = hiera('management_vip', undef)
$database_vip   = hiera('database_vip', undef)

$mysql_root_user     = pick($mysql_hash['root_user'], 'root')
$mysql_db_create     = pick($mysql_hash['db_create'], true)
$mysql_root_password = $mysql_hash['root_password']

$db_type     = 'mysql'
$db_user     = pick($ironic_hash['db_user'], 'ironic')
$db_name     = pick($ironic_hash['db_name'], 'ironic')
$db_password = pick($ironic_hash['db_password'], $mysql_root_password)

$db_host          = pick($ironic_hash['db_host'], $database_vip, $management_vip, 'localhost')
$db_create        = pick($ironic_hash['db_create'], $mysql_db_create)
$db_root_user     = pick($ironic_hash['root_user'], $mysql_root_user)
$db_root_password = pick($ironic_hash['root_password'], $mysql_root_password)

$rabbit_password     = $rabbit_hash['password']
$rabbit_userid       = $rabbit_hash['user']
$rabbit_hosts        = split($amqp_hosts, ',')
$rabbit_virtual_host = '/'

$auth_uri = "http://${management_ip}:5000/v2.0/"
$auth_host = $management_ip


if member($roles, 'controller') or member($roles, 'primary-controller') {
  $ironic_api = true
} else {
  $ironic_api = false
}

#################################################################

if $ironic_hash['enabled'] {

  $database_connection = "${db_type}://${db_user}:${db_password}@${db_host}/${db_name}?charset=utf8&read_timeout=60"

  class { 'openstack::ironic':
#    auth_uri                     => $auth_uri,
#    auth_host                    => $auth_host,
#    auth_user                    => 'ironic',
#    auth_tenant_name             => 'services',
#    auth_password                => $ironic_hash[user_password],

     database_connection          => $database_connection,

#    debug                        => $debug,
#    verbose                      => $verbose,

    rabbit_hosts                 => $rabbit_hosts,
    rabbit_userid                => $rabbit_user,
    rabbit_password              => $rabbit_password,

#    neutron_url                  => "http://${management_ip}:9696",
#    glance_host                  => $management_ip,
    ironic_api           => $ironic_api,
  }

}
/*

  if member($roles, 'controller') or member($roles, 'primary-controller') {

    ####### Disable upstart startup on install #######
    if($::operatingsystem == 'Ubuntu') {
      tweaks::ubuntu_service_override { 'ironic-api':
        package_name => 'ironic-api',
      }
    }

    class { 'ironic::api':
    public_address => $public_ip,
    admin_address => $management_ip,
    internal_address => $management_ip,

    auth_user                    => 'ironic',
    auth_tenant_name             => 'services',
    auth_password                => $ironic_hash[user_password],

    db_password                  => $ironic_hash[db_password],
    db_user                      => 'ironic',
    db_name                      => 'ironic',
    db_host                      => $management_ip,

    neutron_net                  => $neutron_net,
    }

    Class['ironic'] ->
    Class['ironic::api']
  }

  if member($roles, 'ironic-conductor') {
  $neutron_user_password = $neutron_config['keystone']['admin_password']
  $base_mac              = $neutron_config['L2']['base_mac']
  $network_scheme                 = hiera('network_scheme', {})
  if $neutron_config['L2']['mechanism_drivers'] {
      $mechanism_drivers = split($neutron_config['L2']['mechanism_drivers'], ',')
  } else {
      $mechanism_drivers = ['openvswitch']
  }
  if $neutron_config['L2']['provider'] == 'ovs' {
    $core_plugin      = 'openvswitch'
    $agent            = 'ovs'
  } else {
    # by default we use ML2 plugin
    $core_plugin      = 'neutron.plugins.ml2.plugin.Ml2Plugin'
    $agent            = 'ml2-ovs'
  }

  # Required to use get_network_role_property
  prepare_network_config($network_scheme)
  $iface = get_network_role_property('neutron/private', 'phys_dev')
  $baremetal_address = get_network_role_property('baremetal', 'ipaddr')
  $net_mtu = get_transformation_property('mtu', $iface[0])

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
      notify{ $vlan_range:}
    }
  } else {
    $vlan_range = []
  }
  if $pnets['physnet-ironic'] {
    $physnet_ironic = "physnet-ironic:${pnets['physnet-ironic']['bridge']}"
    notify{ $physnet_ironic:}
  }

# TODO: get this shit better
  if $physnet1 and $physnet2 and $physnet-ironic {
    $bridge_mappings = [$physnet1, $physnet2, $physnet-ironic]
  } elsif $physnet1 and $physnet_ironic {
    $bridge_mappings = [$physnet1, $physnet_ironic]
  } elsif $physnet2 and $physnet_ironic {
    $bridge_mappings = [$physnet2, $physnet_ironic]
  } elsif $physnet1 and $physnet2 {
    $bridge_mappings = [$physnet1, $physnet2]
  } elsif $physnet1 {
    $bridge_mappings = [$physnet1]
  } elsif $physnet2 {
    $bridge_mappings = [$physnet2]
  } else {
    $bridge_mappings = []
  }

    ####### Disable upstart startup on install #######
    if($::operatingsystem == 'Ubuntu') {
      tweaks::ubuntu_service_override { 'ironic-conductor':
        package_name => 'ironic-conductor',
      }
    }

class { 'openstack::network':
  network_provider => 'neutron',
  agents           => [$agent],
  nova_neutron     => true,
  net_mtu          => $net_mtu,

  base_mac          => $base_mac,
  core_plugin       => $core_plugin,
  service_plugins   => undef,

  # ovs
  mechanism_drivers   => $mechanism_drivers,
  local_ip            => false,
  bridge_mappings     => $bridge_mappings,
  network_vlan_ranges => $vlan_range,
  enable_tunneling    => false,
  tunnel_id_ranges    => [],
  flat_networks       => ['physnet-ironic'],

  verbose             => $verbose,
  debug               => $debug,
  use_syslog          => $use_syslog,
  syslog_log_facility => hiera('syslog_log_facility_nova', 'LOG_LOCAL4'),

  # queue settings
  queue_provider => 'rabbitmq',
  amqp_hosts     => [$amqp_hosts],
  amqp_user      => $rabbit_hash['user'],
  amqp_password  => $rabbit_hash['password'],

  # keystone
  admin_password => $neutron_user_password,
  auth_url       => "http://${management_ip}:35357/v2.0",
  neutron_url    => "http://${management_ip}:9696",

  # metadata
  shared_secret  => undef,

  integration_bridge => 'br-int',

  # nova settings
  private_interface => false,
  public_interface  => hiera('public_int', undef),
  fixed_range       => false,
  floating_range    => {},
  network_manager   => hiera('network_manager', undef),
  network_config    => hiera('network_config', {}),
  create_networks   => undef,
  num_networks      => hiera('num_networks', undef),
   means that we have failing neutron_ha deployment
test. Thus master branch of fuel-library can not pass Ubuntu test on
CI.

While we are waiting for the fix, we are working on reconfiguration of
CI to support another Ubuntu-based test scenarios (bvt_2 at least,
nova_ha and anything else). ETA 1-2 hours.

Community ISO
-----------------------

Community ISO builds fail due to public mirrors containing Openstacknetwork_size      => hiera('network_size', undef),
  nameservers       => hiera('dns_nameservers', undef),
  enable_nova_net   => false,
}

    class { 'ironic::conductor':
    enabled_drivers              => 'pxe_vbox',
    tftp_server     => $baremetal_address,
    }

    class { 'ironic::tftpd': }

    class { 'ironic::compute':
    auth_uri                     => "http://${management_ip}:35357/v2.0",
    auth_user                    => 'ironic',
    auth_tenant_name             => 'services',
    auth_password                => $ironic_hash[user_password],
    api_endpoint                 => "http://${management_ip}:6385/v1",
    sql_connection              => "mysql://nova:${nova_hash[db_password]}@${management_ip}/nova?read_timeout=60",
    rabbit_hosts                 => $amqp_hosts,
    rabbit_user                  => $rabbit_hash['user'],
    rabbit_ha_queues             => $rabbit_ha_queues,
    rabbit_password              => $rabbit_hash['password'],
    glance_api_servers          => "${management_ip}:9292",
    debug                        => $debug,
    verbose                      => $verbose,
    syslog_log_facility         => hiera('syslog_log_facility_nova','LOG_LOCAL6'),
    nova_report_interval => $nova_report_interval,
    nova_service_down_time => $nova_service_down_time,
    memcached_servers      => $memcached_servers,
    linuxnet_interface_driver => 'nova.network.linux_net.LinuxOVSInterfaceDriver',
    linuxnet_ovs_integration_bridge => 'br-int',
    network_device_mtu => $net_mtu,
    }

    Class['openstack::network'] ->
    Class['ironic'] ->
    Class['ironic::conductor'] ->
    Class['ironic::tftpd'] ->
    Class['ironic::compute']
  }
}

#########################


#class openstack::firewall {}
#include openstack::firewall
*/
