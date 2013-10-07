# setup Ceph monitors
class ceph::mon {

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

  exec {'ceph-deploy gatherkeys':
    command => "ceph-deploy gatherkeys ${::hostname}",
    creates => ['/root/ceph.bootstrap-mds.keyring',
                '/root/ceph.bootstrap-osd.keyring',
                '/root/ceph.client.admin.keyring',
               ],
  }

  # creates the named OSD pool
  define osd_pool {
    exec { "Creating pool ${name}":
      command   => "ceph osd pool create ${name} ${::ceph::osd_pool_default_pg_num} ${::ceph::osd_pool_default_pgp_num}",
      logoutput => true,
    }
  }
  osd_pool {[$::ceph::cinder_pool, $::ceph::glance_pool]: }

  Firewall['010 ceph-mon allow'] ->
  Exec['ceph-deploy mon create'] ->
  Exec['Wait for Ceph quorum']   ->
  Exec['ceph-deploy gatherkeys'] ->
  Osd_pool <||>
}
