# setup Ceph monitors
class ceph::mon {
  include ceph::osd_pools

  firewall {'010 ceph-mon allow':
    chain  => 'INPUT',
    dport  => 6789,
    proto  => 'tcp',
    action => accept,
  }

  exec {'ceph-deploy mon create':
    command   => "ceph-deploy mon create ${::hostname}:${::internal_address}",
    logoutput => true,
    unless    => 'ceph -s',
    # TODO: need method to update mon_nodes in ceph.conf
  }

  exec {'Wait for Ceph quorum':
    # this can be replaced with "ceph mon status mon.$::host" for Dumpling
    command   => 'ps ax|grep -vq ceph-create-keys',
    returns   => 0,
    tries     => 60,  # This is necessary to prevent a race: mon must establish
    # a quorum before it can generate keys, observed this takes upto 15 seconds
    # Keys must exist prior to other commands running
    try_sleep => 1,
  }

  Firewall['010 ceph-mon allow'] ->
  Exec['ceph-deploy mon create'] ->
  Exec['Wait for Ceph quorum']   ->
  Class['ceph::osd_pools']
}

# creates Ceph OSD pools for Cinder and Glance
class ceph::osd_pools {
  # creates the named osd pool
  define osd_pool {
    exec { "Creating pool ${name}":
      command   => "ceph osd pool create ${name} ${::ceph::osd_pool_default_pg_num} ${::ceph::osd_pool_default_pgp_num}",
      logoutput => true,
    }
  }
  $pools = [ $::ceph::cinder_pool, $::ceph::glance_pool ]
  osd_pool { $pools: }
}
