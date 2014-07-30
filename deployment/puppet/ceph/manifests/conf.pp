# create new conf on primary Ceph MON, pull conf on all other nodes
class ceph::conf {
  if $::hostname == $::ceph::primary_mon {

    exec {'ceph-deploy new':
      command   => "ceph-deploy new ${::hostname}:${::internal_address}",
      cwd       => '/etc/ceph',
      logoutput => true,
      creates   => '/etc/ceph/ceph.conf',
    }

    # link is necessary to work around http://tracker.ceph.com/issues/6281
    file {'/root/ceph.conf':
      ensure => link,
      target => '/etc/ceph/ceph.conf',
    }

    file {'/root/ceph.mon.keyring':
      ensure => link,
      target => '/etc/ceph/ceph.mon.keyring',
    }

    ceph_conf {
      'global/auth_supported':            value => $::ceph::auth_supported;
      'global/osd_journal_size':          value => $::ceph::osd_journal_size;
      'global/osd_mkfs_type':             value => $::ceph::osd_mkfs_type;
      'global/osd_pool_default_size':     value => $::ceph::osd_pool_default_size;
      'global/osd_pool_default_min_size': value => $::ceph::osd_pool_default_min_size;
      'global/osd_pool_default_pg_num':   value => $::ceph::osd_pool_default_pg_num;
      'global/osd_pool_default_pgp_num':  value => $::ceph::osd_pool_default_pgp_num;
      'global/cluster_network':           value => $::ceph::cluster_network;
      'global/public_network':            value => $::ceph::public_network;
    }

    Exec['ceph-deploy new'] ->
    File['/root/ceph.conf'] -> File['/root/ceph.mon.keyring'] ->
    Ceph_conf <||>

  } else {

    exec {'ceph-deploy config pull':
      command => "ceph-deploy --overwrite-conf config pull ${::ceph::primary_mon}",
      cwd     => '/etc/ceph',
      creates => '/etc/ceph/ceph.conf',
    }

    file {'/root/ceph.conf':
      ensure => link,
      target => '/etc/ceph/ceph.conf',
    }

    exec {'ceph-deploy gatherkeys remote':
      command => "ceph-deploy gatherkeys ${::ceph::primary_mon}",
      creates => ['/root/ceph.bootstrap-mds.keyring',
                  '/root/ceph.bootstrap-osd.keyring',
                  '/root/ceph.client.admin.keyring',
                  '/root/ceph.mon.keyring',
                 ],
    }

    file {'/etc/ceph/ceph.client.admin.keyring':
      ensure => file,
      source => '/root/ceph.client.admin.keyring',
      mode   => '0600',
      owner  => 'root',
      group  => 'root',
    }

    exec {'ceph-deploy init config':
      command => "ceph-deploy --overwrite-conf config push ${::hostname}",
      creates => '/etc/ceph/ceph.conf',
    }

    Exec['ceph-deploy config pull'] ->
      File['/root/ceph.conf'] ->
        Exec['ceph-deploy gatherkeys remote'] ->
          File['/etc/ceph/ceph.client.admin.keyring'] ->
            Exec['ceph-deploy init config']
  }
}
