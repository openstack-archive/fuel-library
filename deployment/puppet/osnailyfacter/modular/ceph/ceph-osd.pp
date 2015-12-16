# TODO(bogdando) add monit ceph-osd services monitoring, if required
notice('MODULAR: ceph-osd.pp')

firewall { '011 ceph-osd allow':
  chain  => 'INPUT',
  dport  => '6800-7100',
  proto  => 'tcp',
  action => accept,
}

Ceph::Key {
  inject => false,
}

ceph::key { 'client.admin':
  secret  => hiera('admin_key'),
  cap_mon => 'allow *',
  cap_osd => 'allow *',
  cap_mds => 'allow',
}

$storage_hash = hiera('storage', {})
$osd_journal_size = hiera(osd_journal_size, "2048")

$mon_address_map = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceph_monitor_nodes'), 'ceph/public')

prepare_network_config(hiera_hash('network_scheme'))
$ceph_cluster_network    = get_network_role_property('ceph/replication', 'network')
$ceph_public_network     = get_network_role_property('ceph/public', 'network')

$osd_devices_hash = osd_devices_hash($::osd_devices_list)

class {'ceph::osds':
 args => $osd_devices_hash,
}

class { 'ceph':
  fsid                     => hiera('fsid'),
  osd_journal_size         => $osd_journal_size,
  osd_pool_default_pg_num  => $storage_hash['pg_num'],
  osd_pool_default_pgp_num => $storage_hash['pg_num'],
  osd_pool_default_size    => $storage_hash['osd_pool_size'],
  mon_initial_members      => keys($mon_address_map),
  mon_host                 => values($mon_address_map),
  cluster_network          => $ceph_cluster_network,
  public_network           => $ceph_public_network,
} ->

ceph::key {'client.bootstrap-osd':
   keyring_path => '/var/lib/ceph/bootstrap-osd/ceph.keyring',
   secret       => hiera('bootstrap_osd_key'),
}

