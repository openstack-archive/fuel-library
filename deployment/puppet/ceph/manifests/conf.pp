# create new conf on primary Ceph MON, pull conf on all other nodes
class ceph::conf (
  $mon_addr       = $::ceph::mon_addr,
  $node_hostname  = $::ceph::node_hostname,

) {

  file {'/etc/ceph':
    ensure => directory,
  }

  if $node_hostname == $::ceph::primary_mon {

    exec {'ceph-deploy new':
      command   => "ceph-deploy new ${node_hostname}:${mon_addr}",
      cwd       => '/etc/ceph',
      logoutput => true,
      creates   => '/etc/ceph/ceph.conf',
    }

    # link is necessary to work around http://tracker.ceph.com/issues/6281
    file {"${::ceph::svc_user_homedir}/ceph.conf":
      ensure => link,
      target => '/etc/ceph/ceph.conf',
    }

    file {"${::ceph::svc_user_homedir}/ceph.mon.keyring":
      ensure => link,
      target => '/etc/ceph/ceph.mon.keyring',
    }

    ceph_conf {
      'global/auth_supported':                     value => $::ceph::auth_supported;
      'global/osd_journal_size':                   value => $::ceph::osd_journal_size;
      'global/osd_mkfs_type':                      value => $::ceph::osd_mkfs_type;
      'global/osd_pool_default_size':              value => $::ceph::osd_pool_default_size;
      'global/osd_pool_default_min_size':          value => $::ceph::osd_pool_default_min_size;
      'global/osd_pool_default_pg_num':            value => $::ceph::osd_pool_default_pg_num;
      'global/osd_pool_default_pgp_num':           value => $::ceph::osd_pool_default_pgp_num;
      'global/cluster_network':                    value => $::ceph::cluster_network;
      'global/public_network':                     value => $::ceph::public_network;
      'global/log_to_syslog':                      value => $::ceph::use_syslog;
      'global/log_to_syslog_level':                value => $::ceph::syslog_log_level;
      'global/log_to_syslog_facility':             value => $::ceph::syslog_log_facility;
      'global/osd_max_backfills':                  value => $::ceph::osd_max_backfills;
      'global/osd_recovery_max_active':            value => $::ceph::osd_recovery_max_active;
      'client/rbd_cache':                          value => $::ceph::rbd_cache;
      'client/rbd_cache_writethrough_until_flush': value => $::ceph::rbd_cache_writethrough_until_flush;
    }

    Exec['ceph-deploy new'] ->
    File["${::ceph::svc_user_homedir}/ceph.conf"] -> File["${::ceph::svc_user_homedir}/ceph.mon.keyring"] ->
    Ceph_conf <||>

  } else {

    exec {'ceph-deploy config pull':
      command   => "ceph-deploy --overwrite-conf config pull ${::ceph::primary_mon}",
      cwd       => '/etc/ceph',
      creates   => '/etc/ceph/ceph.conf',
      tries     => 5,
      try_sleep => 2,
    }

    file {"${::ceph::svc_user_homedir}/ceph.conf":
      ensure => link,
      target => '/etc/ceph/ceph.conf',
    }

    exec {'ceph-deploy gatherkeys remote':
      command   => "ceph-deploy gatherkeys ${::ceph::primary_mon}",
      creates   => ["${::ceph::svc_user_homedir}/ceph.bootstrap-mds.keyring",
                    "${::ceph::svc_user_homedir}/ceph.bootstrap-osd.keyring",
                    "${::ceph::svc_user_homedir}/ceph.client.admin.keyring",
                    "${::ceph::svc_user_homedir}/ceph.mon.keyring",],
      tries     => 5,
      try_sleep => 2,
    }

    file {'/etc/ceph/ceph.client.admin.keyring':
      ensure => file,
      source => "${::ceph::svc_user_homedir}/ceph.client.admin.keyring",
      mode   => '0600',
      owner  => $::ceph::svc_user::name,
      group  => $::ceph::svc_user::name,
    }

    exec {'ceph-deploy init config':
      command => "ceph-deploy --overwrite-conf config push ${::hostname}",
      creates => '/etc/ceph/ceph.conf',
    }

    ceph_conf {
      'global/cluster_network': value => $::ceph::cluster_network;
      'global/public_network':  value => $::ceph::public_network;
    }

    Exec['ceph-deploy config pull'] ->
      File["${::ceph::svc_user_homedir}/ceph.conf"] ->
        Ceph_conf[['global/cluster_network', 'global/public_network']] ->
          Exec['ceph-deploy gatherkeys remote'] ->
            File['/etc/ceph/ceph.client.admin.keyring'] ->
              Exec['ceph-deploy init config']
  }
}
