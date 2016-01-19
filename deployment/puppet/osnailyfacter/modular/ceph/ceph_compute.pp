notice('MODULAR: ceph/ceph_compute.pp')

$mon_address_map          = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceph_monitor_nodes'), 'ceph/public')
$storage_hash             = hiera_hash('storage_hash', {})
$use_neutron              = hiera('use_neutron')
$public_vip               = hiera('public_vip')
$management_vip           = hiera('management_vip')
$use_syslog               = hiera('use_syslog', true)
$syslog_log_facility_ceph = hiera('syslog_log_facility_ceph','LOG_LOCAL0')
$keystone_hash            = hiera_hash('keystone_hash', {})
# Cinder settings
$cinder_pool              = 'volumes'
# Glance settings
$glance_pool              = 'images'
#Nova Compute settings
$compute_user             = 'compute'
$compute_pool             = 'compute'


if ($storage_hash['images_ceph']) {
  $glance_backend = 'ceph'
} elsif ($storage_hash['images_vcenter']) {
  $glance_backend = 'vmware'
} else {
  $glance_backend = 'swift'
}

if ($storage_hash['volumes_ceph'] or
  $storage_hash['images_ceph'] or
  $storage_hash['objects_ceph'] or
  $storage_hash['ephemeral_ceph']
) {
  $use_ceph = true
} else {
  $use_ceph = false
}

if $use_ceph {
  $ceph_primary_monitor_node = hiera('ceph_primary_monitor_node')
  $primary_mons              = keys($ceph_primary_monitor_node)
  $primary_mon               = $ceph_primary_monitor_node[$primary_mons[0]]['name']

  prepare_network_config(hiera_hash('network_scheme', {}))
  $ceph_cluster_network = get_network_role_property('ceph/replication', 'network')
  $ceph_public_network  = get_network_role_property('ceph/public', 'network')

  class {'ceph':
    primary_mon              => $primary_mon,
    mon_hosts                => keys($mon_address_map),
    mon_ip_addresses         => values($mon_address_map),
    cluster_node_address     => $public_vip,
    osd_pool_default_size    => $storage_hash['osd_pool_size'],
    osd_pool_default_pg_num  => $storage_hash['pg_num'],
    osd_pool_default_pgp_num => $storage_hash['pg_num'],
    use_rgw                  => false,
    glance_backend           => $glance_backend,
    rgw_pub_ip               => $public_vip,
    rgw_adm_ip               => $management_vip,
    rgw_int_ip               => $management_vip,
    cluster_network          => $ceph_cluster_network,
    public_network           => $ceph_public_network,
    use_syslog               => $use_syslog,
    syslog_log_level         => hiera('syslog_log_level_ceph', 'info'),
    syslog_log_facility      => $syslog_log_facility_ceph,
    rgw_keystone_admin_token => $keystone_hash['admin_token'],
    ephemeral_ceph           => $storage_hash['ephemeral_ceph']
  }


  service { $::ceph::params::service_nova_compute :}

  ceph::pool {$compute_pool:
    user          => $compute_user,
    acl           => "mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=${cinder_pool}, allow rx pool=${glance_pool}, allow rwx pool=${compute_pool}'",
    keyring_owner => 'nova',
    pg_num        => $storage_hash['pg_num'],
    pgp_num       => $storage_hash['pg_num'],
  }

  include ceph::nova_compute

  if ($storage_hash['ephemeral_ceph']) {
    include ceph::ephemeral
    Class['ceph::conf'] -> Class['ceph::ephemeral'] ~>
    Service[$::ceph::params::service_nova_compute]
  }

  Class['ceph::conf'] ->
  Ceph::Pool[$compute_pool] ->
  Class['ceph::nova_compute'] ~>
  Service[$::ceph::params::service_nova_compute]

  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
    cwd  => '/root',
  }

}
