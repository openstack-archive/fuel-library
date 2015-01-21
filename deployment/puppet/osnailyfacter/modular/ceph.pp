# Pulling hiera

$internal_int = hiera('internal_int')
$public_int = hiera('public_int', undef)
$public_vip = hiera('public_vip')
$management_vip = hiera('management_vip')
$internal_address = hiera('internal_address')
$primary_controller = hiera('primary_controller')
$storage_address = hiera('storage_address')
$use_neutron = hiera('use_neutron')
$neutron_nsx_config = hiera('nsx_plugin')
$cinder_nodes_array = hiera('cinder_nodes', [])
$sahara_hash = hiera('sahara', {})
$murano_hash = hiera('murano', {})
$heat_hash  = hiera('heat', {})
$mp_hash              = hiera('mp')
$verbose = true
$debug = hiera('debug', true)
$use_monit = false
$mongo_hash = hiera('mongo', {})
$auto_assign_floating_ip = hiera('auto_assign_floating_ip', false)
$nodes_hash                     = hiera('nodes', {})
$storage_hash                   = hiera('storage', {})
$syslog_hash                    = hiera('syslog', {})
$base_syslog_hash               = hiera('base_syslog', {})
$vcenter_hash                   = hiera('vcenter', {})
$nova_hash                      = hiera('nova', {})
$mysql_hash                     = hiera('mysql', {})
$rabbit_hash                    = hiera('rabbit', {})
$glance_hash                    = hiera('glance', {})
$keystone_hash                  = hiera('keystone', {})
$swift_hash                     = hiera('swift', {})
$cinder_hash                    = hiera('cinder', {})
$ceilometer_hash                = hiera('ceilometer',{})
$access_hash                    = hiera('access', {})
$network_scheme                 = hiera('network_scheme', {})
$network_data                   = hiera('network_data', {})
$syslog_log_facility_ceph       = hiera('syslog_log_facility_ceph','LOG_LOCAL0')
$controllers                    = hiera('controllers')

$use_syslog = hiera('use_syslog', true)
$neutron_mellanox = hiera('neutron_mellanox', false)

# TODO: openstack_version is confusing, there's such string var in hiera and hardcoded hash
$hiera_openstack_version = hiera('openstack_version')
$openstack_version = {
  'keystone'   => 'installed',
  'glance'     => 'installed',
  'horizon'    => 'installed',
  'nova'       => 'installed',
  'novncproxy' => 'installed',
  'cinder'     => 'installed',
}

$queue_provider='rabbitmq'
$custom_mysql_setup_class='galera'

#################################################################
$primary_mons   = $controllers
$primary_mon    = $controllers[0]['name']

if ($use_neutron) {
  prepare_network_config($network_scheme)
  $ceph_cluster_network = get_network_role_property('storage', 'cidr')
  $ceph_public_network  = get_network_role_property('management', 'cidr')
} else {
  $ceph_cluster_network = hiera('storage_network_range')
  $ceph_public_network = hiera('management_network_range')
}

class {'ceph':
  primary_mon              => $primary_mon,
  mon_hosts                => nodes_with_roles($nodes_hash, ['primary-controller',
                                               'controller', 'ceph-mon'], 'name'),
  mon_ip_addresses         => nodes_with_roles($nodes_hash, ['primary-controller',
                                               'controller', 'ceph-mon'], 'internal_address'),
  cluster_node_address     => $controller_node_public,
  osd_pool_default_size    => $storage_hash['osd_pool_size'],
  osd_pool_default_pg_num  => $storage_hash['pg_num'],
  osd_pool_default_pgp_num => $storage_hash['pg_num'],
  use_rgw                  => $storage_hash['objects_ceph'],
  glance_backend           => $glance_backend,
  rgw_pub_ip               => $public_vip,
  rgw_adm_ip               => $management_vip,
  rgw_int_ip               => $management_vip,
  cluster_network          => $ceph_cluster_network,
  public_network           => $ceph_public_network,
  use_syslog               => $use_syslog,
  syslog_log_level         => $syslog_log_level,
  syslog_log_facility      => $syslog_log_facility_ceph,
  rgw_keystone_admin_token => $keystone_hash['admin_token'],
  ephemeral_ceph           => $storage_hash['ephemeral_ceph']
}

#################################################################

# vim: set ts=2 sw=2 et :
