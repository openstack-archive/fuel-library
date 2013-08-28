class ceph::deploy (
  $auth_supported = 'cephx',
  $osd_journal_size = '2048',
  $osd_mkfs_type = 'xfs',
  $osd_pool_default_size = '2',
  $osd_pool_default_min_size = '0',
  $osd_pool_default_pg_num = '8',
  $osd_pool_default_pgp_num = '8',
  $cluster_network = '10.0.0.0/24',
  $public_network = '192.168.0.0/24',
  $host = $hostname,
  $keyring_path = '/etc/ceph/keyring.radosgw.gateway',
  $rgw_socket_path = '/tmp/radosgw.sock',
  $log_file = '/var/log/ceph/radosgw.log',
  $user = 'www-data',
  $rgw_keystone_url = '127.0.0.1:5000',
  $rgw_keystone_admin_token = 'nova',
  $rgw_keystone_token_cache_size = '10',
  $rgw_keystone_revocation_interval = '60',
  $rgw_data = '/var/lib/ceph/rados',
  $rgw_dns_name = $hostname,
  $rgw_print_continue = 'false',
  $nss_db_path = '/etc/ceph/nss',
) {
  include p_osd, c_osd, c_pools
  
  $range = join($mon_nodes, " ")
  exec { 'ceph-deploy init config':
    command => "ceph-deploy new ${range}",
    require => Package['ceph-deploy', 'ceph', 'python-pushy'],
    #TODO: see if add creates is relevant
    logoutput => true,
  }
  Ceph_conf {require => Exec['ceph-deploy init config']}
  ceph_conf {
    'global/auth supported':                                   value => $auth_supported;
    'global/osd journal size':                                 value => $osd_journal_size;
    'global/osd mkfs type':                                    value => $osd_mkfs_type;
    'global/osd pool default size':                            value => $osd_pool_default_size;
    'global/osd pool default min size':                        value => $osd_pool_default_min_size;
    'global/osd pool default pg num':                          value => $osd_pool_default_pg_num;
    'global/osd pool default pgp num':                         value => $osd_pool_default_pgp_num;
    'global/cluster network':                                  value => $cluster_network;
    'global/public network':                                   value => $public_network;
    'client.radosgw.gateway/host':                             value => $host;
    'client.radosgw.gateway/keyring':                          value => $keyring_path;
    'client.radosgw.gateway/rgw socket path':                  value => $rgw_socket_path;
    'client.radosgw.gateway/log file':                         value => $log_file;
    'client.radosgw.gateway/user':                             value => $user;
    'client.radosgw.gateway/rgw keystone url':                 value => $rgw_keystone_url;
    'client.radosgw.gateway/rgw keystone admin token':         value => $rgw_keystone_admin_token;
    'client.radosgw.gateway/rgw keystone accepted roles':      value => $rgw_keystone_accepted_roles;
    'client.radosgw.gateway/rgw keystone token cache size':    value => $rgw_keystone_token_cache_size;
    'client.radosgw.gateway/rgw keystone revocation interval': value => $rgw_keystone_revocation_interval;
    'client.radosgw.gateway/rgw data':                         value => $rgw_data;
    'client.radosgw.gateway/rgw dns name':                     value => $rgw_dns_name;
    'client.radosgw.gateway/rgw print continue':               value => $rgw_print_continue;
    'client.radosgw.gateway/nss db path':                      value => $nss_db_path;
  }
  Ceph_conf <||> -> Exec ['ceph-deploy deploy monitors']
  exec { 'ceph-deploy deploy monitors':
    #TODO: evaluate if this is idempotent
    command => "ceph-deploy --overwrite-conf mon create ${range}",
    #    require => Ceph_conf['global/auth supported', 'global/osd journal size', 'global/osd mkfs type']
    logoutput => true,
  } -> exec { 'ceph-deploy gatherkeys':
    command   => "ceph-deploy gatherkeys $fqdn",
    returns   => 0,
    tries     => 60,  #This is necessary to prevent race, mon must establish
    # a quorum before it can generate keys, observed this takes upto 15 times.
    # Keys must exist prior to other commands running
    try_sleep => 1,
    creates   => ['/root/ceph.bootstrap-osd.keyring',
                  '/root/ceph.bootstrap-mds.keyring',
                  '/root/ceph.client.admin.keyring'],
  }
  File {
#    ensure => 'link',
    require => Exec['ceph-deploy gatherkeys']
  }
  file { '/root/ceph.bootstrap-osd.keyring':
#    target => '/var/lib/ceph/bootstrap-osd/ceph.keyring',
  }
  file { '/root/ceph.bootstrap-mds.keyring':
#    target => '/var/lib/ceph/bootstrap-mds/ceph.keyring',
  }
  file { '/root/ceph.client.admin.keyring':
#    target => "/etc/ceph/ceph.client.admin.keyring",
  }
  class p_osd {
    define int {
      $devices = join(suffix($osd_nodes, ":${name}"), " ")
      exec { "ceph-deploy osd prepare ${devices}":
        #ceph-deploy osd prepare is ensuring there is a filesystem on the
        # disk according to the args passed to ceph.conf (above).
        #timeout: It has a long timeout because of the format taking forever.
        # A resonable amount of time would be around 300 times the length
        # of $osd_nodes. Right now its 0 to prevent puppet from aborting it.
        command => "ceph-deploy osd prepare ${devices}",
        returns => 0,
        timeout => 0, #TODO: make this something reasonable
        tries => 2,  #This is necessary because of race for mon creating keys
        try_sleep => 1,
        require => [File['/root/ceph.bootstrap-osd.keyring',
                         '/root/ceph.bootstrap-mds.keyring',
                         '/root/ceph.client.admin.keyring'],
                    Exec['ceph-deploy gatherkeys'],
                    ],
        logoutput => true,
      }
    }
    int { $osd_devices: }
  }
  class c_osd {
    define int {
      $devices = join(suffix($osd_nodes, ":${name}"), " ")
      exec { "Creating osd`s on ${devices}":
        command => "ceph-deploy osd activate ${devices}",
        returns => 0,
        require => Class['p_osd'],
        logoutput => true,
      }
    }
    int { $osd_devices: }
  }
  if $mds_server {
    exec { 'ceph-deploy-s4':
      command => "ceph-deploy mds create ${mds_server}",
      require => Class['c_osd'],
      logoutput => true,
    }
  }
  class c_pools {
    define int {
      exec { "Creating pool ${name}":
        command => "ceph osd pool create ${name} ${osd_pool_default_pg_num} ${osd_pool_default_pgp_num}",
        require => Class['c_osd'],
        logoutput => true,
      }
    }
    int { $ceph_pools: }
  }
  exec { 'CLIENT AUTHENTICATION':
    #DO NOT SPLIT ceph auth command lines See http://tracker.ceph.com/issues/3279
    command => "ceph auth get-or-create client.${ceph_pools[0]} mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=${ceph_pools[0]}, allow rx pool=${ceph_pools[1]}' && \
    ceph auth get-or-create client.${ceph_pools[1]} mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=${ceph_pools[1]}'",
    require => Class['c_pools'],
    logoutput => true,
  }

#TODO: remove below here when we can do deploy from each mon (PRD-1570)
  exec { 'ceph auth get client.volumes':
    command => 'ceph auth get-or-create client.volumes > /etc/ceph/ceph.client.volumes.keyring',
    before  => File['/etc/ceph/ceph.client.volumes.keyring'],
    require => [Package['ceph']],
    returns => 0,
  }
  exec { 'ceph auth get client.images':
    command => 'ceph auth get-or-create client.images > /etc/ceph/ceph.client.images.keyring',
    before  => File['/etc/ceph/ceph.client.images.keyring'],
    require => [Package['ceph']],
    returns => 0,
  }
  exec {'Deploy push config':
    #This pushes config and keyrings  to other nodes
    command => "for node in ${mon_nodes}
  do
    scp -r /etc/ceph/* \${node}:/etc/ceph/ 
  done",
    require => [Exec['CLIENT AUTHENTICATION',
                     'ceph auth get client.volumes',
                     'ceph auth get client.images'],
               ],
    returns => 0,
  }
}
