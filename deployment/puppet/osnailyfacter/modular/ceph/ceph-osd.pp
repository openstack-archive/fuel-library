notice('MODULAR: ceph-osd.pp')

# Pulling hiera
$public_vip                = hiera('public_vip')
$management_vip            = hiera('management_vip')
$use_neutron               = hiera('use_neutron', false)
$mp_hash                   = hiera('mp')
$verbose                   = true
$debug                     = hiera('debug', true)
$use_monit                 = false
$auto_assign_floating_ip   = hiera('auto_assign_floating_ip', false)
$storage_hash              = hiera_hash('storage', {})
$keystone_hash             = hiera_hash('keystone', {})
$access_hash               = hiera_hash('access', {})
$network_scheme            = hiera_hash('network_scheme', {})
$syslog_hash               = hiera_hash('syslog', {})
$neutron_mellanox          = hiera('neutron_mellanox', false)
$use_syslog                = hiera('use_syslog', true)
$ceph_primary_monitor_node = hiera('ceph_primary_monitor_node')

$mon_address_map           = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceph_monitor_nodes'), 'ceph/public')
$primary_mons              = keys($ceph_primary_monitor_node)
$primary_mon               = $ceph_primary_monitor_node[$primary_mons[0]]['name']
prepare_network_config($network_scheme)
$ceph_cluster_network      = get_network_role_property('ceph/replication', 'network')
$ceph_public_network       = get_network_role_property('ceph/public', 'network')

class {'ceph':
  primary_mon              => $primary_mon,
  mon_hosts                => keys($mon_address_map),
  mon_ip_addresses         => values($mon_address_map),
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
  syslog_log_level         => hiera('syslog_log_level_ceph', 'info'),
  syslog_log_facility      => hiera('syslog_log_facility_ceph','LOG_LOCAL0'),
  rgw_keystone_admin_token => $keystone_hash['admin_token'],
  ephemeral_ceph           => $storage_hash['ephemeral_ceph'],
}

$osd_devices = split($::osd_devices_list, ' ')
#Class Ceph is already defined so it will do it's thing.
notify {"ceph_osd: ${osd_devices}": }
notify {"osd_devices:  ${::osd_devices_list}": }
# TODO(bogdando) add monit ceph-osd services monitoring, if required

#################################################################

# vim: set ts=2 sw=2 et :
