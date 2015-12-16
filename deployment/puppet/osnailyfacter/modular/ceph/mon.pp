notice('MODULAR: ceph/mon.pp')

firewall {'010 ceph-mon allow':
  chain  => 'INPUT',
  dport  => 6789,
  proto  => 'tcp',
  action => accept,
}

$mon_address_map = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceph_monitor_nodes'), 'ceph/public')
$primary_mon = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceph_primary_monitor_node'), 'ceph/public')

$mon_ips = join(values($mon_address_map), ',')
$mon_hosts = join(keys($mon_address_map), ',')

$primary_mon_hostname = join(keys($primary_mon))
$primary_mon_ip = join(values($primary_mon))

# FUEL ships it's own ceph packages
# class { 'ceph::repo':}

# this is required, as puppet-ceph manifests requires
# all monitors to be deployed in parrallel, while
# FUEL deploys primary monitor first
# So primary monitor always deployed as a single
# monitor. And that it config gets updated from secondary
# monitor

if $primary_mon_hostname == $::hostname {
  $mon_initial_members = $primary_mon_hostname
  $mon_host = $primary_mon_ip
} else {
  $mon_initial_members = $mon_hosts
  $mon_host = $mon_ips
}

# if this is second monitor
if $second_mon == $::hostname and hiera('ceph_primary_monitor_node') != $::hostname {
  # update monitor config on primary monitor and restart mon
  # on primary mon node
}

class { 'ceph':
  fsid                     => hiera('fsid'),
  mon_initial_members      => $mon_initial_members,
  mon_host                 => $mon_host,
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
