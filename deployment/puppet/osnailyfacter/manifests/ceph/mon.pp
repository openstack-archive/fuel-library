class osnailyfacter::ceph::mon {

  notice('MODULAR: ceph/mon.pp')

  $storage_hash              = hiera('storage', {})
  $admin_key                 = pick($storage_hash['admin_key'], 'AQCTg71RsNIHORAAW+O6FCMZWBjmVfMIPk3MhQ==')
  $mon_key                   = pick($storage_hash['mon_key'], 'AQDesGZSsC7KJBAAw+W/Z4eGSQGAIbxWjxjvfw==')
  $bootstrap_osd_key         = pick($storage_hash['bootstrap_osd_key'], 'AQABsWZSgEDmJhAAkAGSOOAJwrMHrM5Pz5On1A==')
  $fsid                      = pick($storage_hash['fsid'], '066F558C-6789-4A93-AAF1-5AF1BA01A3AD')
  $osd_pool_default_size     = $storage_hash['osd_pool_size']
  $osd_pool_default_pg_num   = $storage_hash['pg_num']
  $osd_pool_default_pgp_num  = $storage_hash['pg_num']
  $osd_pool_default_min_size = pick($storage_hash['osd_pool_default_min_size'], '1')
  $osd_journal_size          = pick($storage_hash['osd_journal_size'],  '2048')

  $mon_address_map = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceph_monitor_nodes'), 'ceph/public')
  $primary_mon     = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceph_primary_monitor_node'), 'ceph/public')

  $mon_ips   = join(values($mon_address_map), ',')
  $mon_hosts = join(keys($mon_address_map), ',')

  $primary_mon_hostname = join(keys($primary_mon))
  $primary_mon_ip       = join(values($primary_mon))

  prepare_network_config(hiera_hash('network_scheme'))
  $ceph_cluster_network = get_network_role_property('ceph/replication', 'network')
  $ceph_public_network  = get_network_role_property('ceph/public', 'network')

  if $primary_mon_hostname == $::hostname {
    $mon_initial_members = $primary_mon_hostname
    $mon_host            = $primary_mon_ip
  } else {
    $mon_initial_members = $mon_hosts
    $mon_host            = $mon_ips
  }

  if ($storage_hash['volumes_ceph'] or
    $storage_hash['images_ceph'] or
    $storage_hash['objects_ceph'] or
    $storage_hash['ephemeral_ceph']
  ) {
    $use_ceph = true
  } else {
    $use_ceph = false
  }

  if $use_ceph {
    class { '::ceph':
      fsid                      => $fsid,
      mon_initial_members       => $mon_initial_members,
      mon_host                  => $mon_host,
      cluster_network           => $ceph_cluster_network,
      public_network            => $ceph_public_network,
      osd_pool_default_size     => $osd_pool_default_size,
      osd_pool_default_pg_num   => $osd_pool_default_pg_num,
      osd_pool_default_pgp_num  => $osd_pool_default_pgp_num,
      osd_pool_default_min_size => $osd_pool_default_min_size,
      osd_journal_size          => $osd_journal_size,
    }

    ceph_config {
      'global/osd_mkfs_type'                      : value => 'xfs';
      'global/filestore_xattr_use_omap'           : value => true;
      'global/osd_recovery_max_active'            : value => '1';
      'global/osd_max_backfills'                  : value => '1';
      'client/rbd_cache_writethrough_until_flush' : value => true;
      'client/rbd_cache'                          : value => true;
      'global/log_to_syslog'                      : value => true;
      'global/log_to_syslog_level'                : value => 'info';
      'global/log_to_syslog_facility'             : value => 'LOG_LOCAL0';
    }

    Ceph::Key {
      inject => true,
      inject_as_id   => 'mon.',
      inject_keyring => "/var/lib/ceph/mon/ceph-${::hostname}/keyring",
    }

    ceph::key { 'client.admin':
      secret  => $admin_key,
      cap_mon => 'allow *',
      cap_osd => 'allow *',
      cap_mds => 'allow',
    }

    ceph::key { 'client.bootstrap-osd':
      secret  => $bootstrap_osd_key,
      cap_mon => 'allow profile bootstrap-osd',
    }

    ceph::mon { $::hostname:
      key => $mon_key,
    }

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
  }

}

