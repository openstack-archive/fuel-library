notice('MODULAR: ceph/ceph_compute.pp')

$mon_address_map          = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceph_monitor_nodes'), 'ceph/public')
$storage_hash             = hiera('storage', {})
$admin_key                = pick($storage_hash['admin_key'], 'AQCTg71RsNIHORAAW+O6FCMZWBjmVfMIPk3MhQ==')
$mon_key                  = pick($storage_hash['mon_key'], 'AQDesGZSsC7KJBAAw+W/Z4eGSQGAIbxWjxjvfw==')
$bootstrap_osd_key        = pick($storage_hash['bootstrap_osd_key'], 'AQABsWZSgEDmJhAAkAGSOOAJwrMHrM5Pz5On1A==')
$fsid                     = pick($storage_hash['fsid'], '066F558C-6789-4A93-AAF1-5AF1BA01A3AD')
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
$libvirt_images_type      = 'rbd'
$secret                   = $mon_key

case $::osfamily {
  'RedHat': {
    $service_nova_compute = 'openstack-nova-compute'
  }
  'Debian': {
    $service_nova_compute = 'nova-compute'
  }
}

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

  prepare_network_config(hiera_hash('network_scheme'))
  $ceph_cluster_network = get_network_role_property('ceph/replication', 'network')
  $ceph_public_network  = get_network_role_property('ceph/public', 'network')

  $per_pool_pg_nums = $storage_hash['per_pool_pg_nums']

  class { 'ceph':
    fsid                     => hiera('fsid'),
    mon_initial_members      => values($mon_address_map),
    mon_host                 => keys($mon_address_map),
    cluster_network          => $ceph_cluster_network,
    public_network           => $ceph_public_network,
  }

  service { $service_nova_compute :}

  ceph::pool { $compute_pool:
    pg_num  => pick($per_pool_pg_nums[$compute_pool], '1024'),
    pgp_num => pick($per_pool_pg_nums[$compute_pool], '1024'),
  }

  ceph::key { "client.${compute_user}":
    secret  => $secret,
    cap_mon => 'allow r',
    cap_osd => "allow class-read object_prefix rbd_children, allow rwx pool=${cinder_pool}, allow rx pool=${glance_pool}, allow rwx pool=${compute_pool}",
    inject  => true,
  }

  include osnailyfacter::ceph_nova_compute

  if ($storage_hash['ephemeral_ceph']) {

    Class['ceph'] ->

    nova_config {
      'libvirt/images_type':      value => $libvirt_images_type;
      'libvirt/inject_key':       value => false;
      'libvirt/inject_partition': value => '-2';
      'libvirt/images_rbd_pool':  value => $compute_pool;
    } ~>

    Service[$service_nova_compute]
  }

  Class['ceph'] ->
  Ceph::Pool[$compute_pool] ->
  Class['osnailyfacter::ceph_nova_compute'] ~>
  Service[$service_nova_compute]

  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
    cwd  => '/root',
  }

}

