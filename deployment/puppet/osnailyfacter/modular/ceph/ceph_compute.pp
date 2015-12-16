notice('MODULAR: ceph/ceph_compute.pp')

Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
  cwd  => '/root',
}

prepare_network_config(hiera_hash('network_scheme'))
$ceph_cluster_network = get_network_role_property('ceph/replication', 'network')
$ceph_public_network  = get_network_role_property('ceph/public', 'network')

$storage_hash = hiera('storage', {})
$osd_journal_size = hiera(osd_journal_size, "2048")
$mon_address_map     = get_node_to_ipaddr_map_by_network_role(
                          hiera_hash('ceph_monitor_nodes'),
                          'ceph/public')

# FUEL ships it's own ceph packages
# class { 'ceph::repo':}

class { 'ceph':
  fsid                     => hiera('fsid'),
  osd_journal_size         => $osd_journal_size,
  osd_pool_default_pg_num  => $storage_hash['pg_num'],
  osd_pool_default_pgp_num => $storage_hash['pg_num'],
  osd_pool_default_size    => $storage_hash['osd_pool_size'],
  mon_initial_members      => values($mon_address_map),
  mon_hosts                => keys($mon_address_map),
  cluster_network          => $ceph_cluster_network,
  public_network           => $ceph_public_network,
}

service { $::ceph::params::service_nova_compute :}

$cinder_pool              = 'volumes'
$glance_pool              = 'images'

if ($storage_hash['ephemeral_ceph']) {
  #Nova Compute settings
  $compute_user             = 'compute'
  $compute_pool             = 'compute'

  Class['ceph'] ->
  ceph::key {"client.${compute_user}":
    cap_mon => "allow r",
    cap_osd => "allow class-read object_prefix rbd_children, allow rwx pool=${cinder_pool}, allow rx pool=${glance_pool}, allow rwx pool=${compute_pool}",
    user => "nova"
  } ->
  ceph::pool {$compute_pool:
    pg_num        => $storage_hash['pg_num'],
    pgp_num       => $storage_hash['pg_num'],
  } ~>
  Service[$::ceph::params::service_nova_compute]
} else {
  Class['ceph'] ->
  ceph::key {"client.${compute_user}":
    cap_mon => "allow r",
    cap_osd => "allow class-read object_prefix rbd_children, allow rwx pool=${cinder_pool}, allow rx pool=${glance_pool}"
    user => "nova"
  } ~>
  Service[$::ceph::params::service_nova_compute]
}
