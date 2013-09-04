class ceph::mon {
  include c_pools

  firewall {'010 ceph-mon allow':
    chain => 'INPUT',
    dport => 6789,
    proto => 'tcp',
    action  => accept,
  }

  ceph_conf {
    'global/auth supported':                                   value => $::ceph::auth_supported;
    'global/osd journal size':                                 value => $::ceph::osd_journal_size;
    'global/osd mkfs type':                                    value => $::ceph::osd_mkfs_type;
    'global/osd pool default size':                            value => $::ceph::osd_pool_default_size;
    'global/osd pool default min size':                        value => $::ceph::osd_pool_default_min_size;
    'global/osd pool default pg num':                          value => $::ceph::osd_pool_default_pg_num;
    'global/osd pool default pgp num':                         value => $::ceph::osd_pool_default_pgp_num;
    'global/cluster network':                                  value => $::ceph::cluster_network;
    'global/public network':                                   value => $::ceph::public_network;
    'client.radosgw.gateway/host':                             value => $::ceph::host;
    'client.radosgw.gateway/keyring':                          value => $::ceph::keyring_path;
    'client.radosgw.gateway/rgw socket path':                  value => $::ceph::rgw_socket_path;
    'client.radosgw.gateway/log file':                         value => $::ceph::log_file;
    'client.radosgw.gateway/user':                             value => $::ceph::user;
    'client.radosgw.gateway/rgw keystone url':                 value => $::ceph::rgw_keystone_url;
    'client.radosgw.gateway/rgw keystone admin token':         value => $::ceph::rgw_keystone_admin_token;
    'client.radosgw.gateway/rgw keystone accepted roles':      value => $::ceph::rgw_keystone_accepted_roles;
    'client.radosgw.gateway/rgw keystone token cache size':    value => $::ceph::rgw_keystone_token_cache_size;
    'client.radosgw.gateway/rgw keystone revocation interval': value => $::ceph::rgw_keystone_revocation_interval;
    'client.radosgw.gateway/rgw data':                         value => $::ceph::rgw_data;
    'client.radosgw.gateway/rgw dns name':                     value => $::ceph::rgw_dns_name;
    'client.radosgw.gateway/rgw print continue':               value => $::ceph::rgw_print_continue;
    'client.radosgw.gateway/nss db path':                      value => $::ceph::nss_db_path;
  }
  Ceph_conf {require => Exec['ceph-deploy init config']}
  Ceph_conf <||> -> Exec ['ceph-deploy deploy monitors']
  exec { 'ceph-deploy deploy monitors':
    command => "ceph-deploy --overwrite-conf mon create ${::hostname}:${::public_address}",
    logoutput => true,
    #TODO: need method to update mon_nodes in ceph.conf
  } -> exec { 'ceph-deploy gatherkeys':
    command   => "ceph-deploy gatherkeys ${::hostname}",
    returns   => 0,
    tries     => 60,  #This is necessary to prevent race, mon must establish
    # a quorum before it can generate keys, observed this takes upto 15 seconds
    # Keys must exist prior to other commands running
    try_sleep => 1,
    require   => [File['/usr/bin/ceph-deploy'],
                  Firewall['010 ceph-mon allow']
                 ],
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
  class c_pools {
    define int {
      exec { "Creating pool ${name}":
        command => "ceph osd pool create ${name} ${::ceph::osd_pool_default_pg_num} ${::ceph::osd_pool_default_pgp_num}",
        require => Exec['ceph-deploy deploy monitors'],
        logoutput => true,
      }
    }
    int { $::ceph::ceph_pools: }
  }
  exec { 'CLIENT AUTHENTICATION':
    #DO NOT SPLIT ceph auth command lines See http://tracker.ceph.com/issues/3279
    command => "ceph auth get-or-create client.${::ceph::ceph_pools[0]} mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=${::ceph::ceph_pools[0]}, allow rx pool=${::ceph::ceph_pools[1]}' && \
    ceph auth get-or-create client.${::ceph::ceph_pools[1]} mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=${::ceph::ceph_pools[1]}'",
    require => Class['c_pools'],
    logoutput => true,
  }
}