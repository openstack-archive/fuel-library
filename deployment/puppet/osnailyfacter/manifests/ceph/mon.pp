class osnailyfacter::ceph::mon {

  notice('MODULAR: ceph/mon.pp')

  $storage_hash              = hiera('storage', {})
  $admin_key                 = $storage_hash['admin_key']
  $mon_key                   = $storage_hash['mon_key']
  $bootstrap_osd_key         = $storage_hash['bootstrap_osd_key']
  $fsid                      = $storage_hash['fsid']
  $osd_pool_default_size     = $storage_hash['osd_pool_size']
  $osd_pool_default_pg_num   = $storage_hash['pg_num']
  $osd_pool_default_pgp_num  = $storage_hash['pg_num']
  $osd_pool_default_min_size = pick($storage_hash['osd_pool_default_min_size'], '1')
  $osd_journal_size          = pick($storage_hash['osd_journal_size'],  '2048')

  $filestore_xattr_use_omap           = pick($storage_hash['filestore_xattr_use_omap'], true)
  $osd_recovery_max_active            = pick($storage_hash['osd_recovery_max_active'], '1')
  $osd_max_backfills                  = pick($storage_hash['osd_max_backfills'], '1')
  $rbd_cache_writethrough_until_flush = pick($storage_hash['rbd_cache_writethrough_until_flush'], true)
  $rbd_cache                          = pick($storage_hash['rbd_cache'], true)
  $log_to_syslog                      = hiera('use_syslog', true)
  $log_to_syslog_level                = pick($storage_hash['ceph_syslog_level'], 'info')
  $log_to_syslog_facility             = pick($storage_hash['ceph_syslog_facility'], 'LOG_LOCAL0')

  $mon_address_map = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceph_monitor_nodes'), 'ceph/public')
  $primary_mon     = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceph_primary_monitor_node'), 'ceph/public')

  $mon_ips   = join(sorted_hosts($mon_address_map, 'ip'), ',')
  $mon_hosts = join(sorted_hosts($mon_address_map, 'host'), ',')

  $primary_mon_ip       = join(sorted_hosts($primary_mon, 'ip'), ',')
  $primary_mon_hostname = join(sorted_hosts($primary_mon, 'host'), ',')

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

    if empty($admin_key) {
      fail('Please provide admin_key')
    }
    if empty($mon_key) {
      fail('Please provide mon_key')
    }
    if empty($fsid) {
      fail('Please provide fsid')
    }
    if empty($bootstrap_osd_key) {
      fail('Please provide bootstrap_osd_key')
    }

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
      'global/filestore_xattr_use_omap'           : value => $filestore_xattr_use_omap;
      'global/osd_recovery_max_active'            : value => $osd_recovery_max_active;
      'global/osd_max_backfills'                  : value => $osd_max_backfills;
      'client/rbd_cache_writethrough_until_flush' : value => $rbd_cache_writethrough_until_flush;
      'client/rbd_cache'                          : value => $rbd_cache;
      'global/log_to_syslog'                      : value => $log_to_syslog;
      'global/log_to_syslog_level'                : value => $log_to_syslog_level;
      'global/log_to_syslog_facility'             : value => $log_to_syslog_facility;
    }

    Ceph::Key {
      inject         => true,
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
