#ceph::mon will install the ceph-mon
class ceph::mon {
  include c_pools

  firewall {'010 ceph-mon allow':
    chain  => 'INPUT',
    dport  => 6789,
    proto  => 'tcp',
    action => accept,
  }

  exec { 'ceph-deploy deploy monitors':
    command   => "ceph-deploy mon create ${::hostname}:${::internal_address}",
    logoutput => true,
    require   => [Exec['ceph-deploy init config'],
    ],
    #TODO: need method to update mon_nodes in ceph.conf
  }
  exec { 'ceph-deploy gatherkeys':
    command   => "ceph-deploy gatherkeys ${::hostname}",
    returns   => 0,
    tries     => 60,  #This is necessary to prevent race, mon must establish
    # a quorum before it can generate keys, observed this takes upto 15 seconds
    # Keys must exist prior to other commands running
    try_sleep => 1,
    require   => [Firewall['010 ceph-mon allow'],
                  Exec['ceph-deploy deploy monitors']],
  }
  File {
    require => Exec['ceph-deploy gatherkeys']
  }
  file { '/root/ceph.bootstrap-osd.keyring':
  }
  file { '/root/ceph.bootstrap-mds.keyring':
  }
  file { '/root/ceph.client.admin.keyring':
  }
  file { '/root/ceph.client.mon.keyring':
  }
  #c_pools is used to loop through the list of $::ceph::ceph_pools
  class c_pools {
    define int {
      exec { "Creating pool ${name}":
        command   => "ceph osd pool create ${name} ${::ceph::osd_pool_default_pg_num} ${::ceph::osd_pool_default_pgp_num}",
        require   => Exec['ceph-deploy gatherkeys'],
        logoutput => true,
      }
    }
    int { $::ceph::ceph_pools: }
  }
  exec { 'CLIENT AUTHENTICATION':
    #DO NOT SPLIT ceph auth command lines See http://tracker.ceph.com/issues/3279
    command   => "ceph auth get-or-create client.${::ceph::ceph_pools[0]} mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=${::ceph::ceph_pools[0]}, allow rx pool=${::ceph::ceph_pools[1]}' && \
    ceph auth get-or-create client.${::ceph::ceph_pools[1]} mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=${::ceph::ceph_pools[1]}'",
    require   => Class['c_pools'],
    logoutput => true,
  }
}