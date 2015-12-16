notice('MODULAR: ceph/mon.pp')

firewall {'010 ceph-mon allow':
  chain  => 'INPUT',
  dport  => 6789,
  proto  => 'tcp',
  action => accept,
}

$mon_address_map = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceph_monitor_nodes'), 'ceph/public')

prepare_network_config(hiera_hash('network_scheme'))
$ceph_cluster_network    = get_network_role_property('ceph/replication', 'network')
$ceph_public_network     = get_network_role_property('ceph/public', 'network')

class { 'ceph':
  fsid                     => hiera('fsid'),
  mon_initial_members      => keys($mon_address_map),
  mon_host                 => values($mon_address_map),
  cluster_network          => $ceph_cluster_network,
  public_network           => $ceph_public_network,
}

Ceph::Key {
  inject         => true,
  inject_as_id   => 'mon.',
  inject_keyring => "/var/lib/ceph/mon/ceph-${::hostname}/keyring",
}

ceph::key { 'client.admin':
  secret  => hiera('admin_key'),
  cap_mon => 'allow *',
  cap_osd => 'allow *',
  cap_mds => 'allow',
}

ceph::key { 'client.bootstrap-osd':
  secret  => hiera('bootstrap_osd_key'),
  cap_mon => 'allow profile bootstrap-osd',
}

ceph::mon { $::hostname:
  key => hiera('mon_key'),
}


$storage_hash = hiera('storage', {})

if ($storage_hash['volumes_ceph']) {
  include ::cinder::params
  service { 'cinder-volume':
    ensure     => 'running',
    name       => $::cinder::params::volume_service,
    hasstatus  => true,
    hasrestart => true,
  }

  service { 'cinder-backup':
    ensure     => 'running',
    name       => $::cinder::params::backup_service,
    hasstatus  => true,
    hasrestart => true,
  }

  Class['ceph'] ~> Service['cinder-volume']
  Class['ceph'] ~> Service['cinder-backup']
}

if ($storage_hash['images_ceph']) {
  include ::glance::params
  service { 'glance-api':
    ensure     => 'running',
    name       => $::glance::params::api_service_name,
    hasstatus  => true,
    hasrestart => true,
  }

  Class['ceph'] ~> Service['glance-api']
}
