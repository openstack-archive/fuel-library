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
    unless    => 'ceph mon stat | grep ${::internal_address}',
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

  Firewall['010 ceph-mon allow'] ->
  Exec['ceph-deploy mon create'] ->
  Exec['Wait for Ceph quorum']   ->
  Exec['ceph-deploy gatherkeys']
}
