# ceph configuration and resource relations
# TODO: split ceph module to submodules instead of using case with roles

class ceph (
# General settings
  $mon_hosts                          = undef,
  $mon_ip_addresses                   = undef,
  $cluster_node_address               = $::ipaddress, # This should be the cluster service address
  $primary_mon                        = $::hostname,  # This should be the first controller
  $mon_addr                           = $::ipaddress, # This needs to be replaced with the address we want to bind the mon to (if this is a mon)
  $node_hostname                      = $::hostname,
  $osd_devices                        = split($::osd_devices_list, ' '),
  $use_ssl                            = false,
  $use_rgw                            = false,

# ceph.conf Global settings
  $auth_supported                     = 'cephx',
  $osd_journal_size                   = '2048',
  $osd_mkfs_type                      = 'xfs',
  $osd_pool_default_size              = undef,
  $osd_pool_default_min_size          = '1',
  $osd_pool_default_pg_num            = undef,
  $osd_pool_default_pgp_num           = undef,
  $cluster_network                    = undef,
  $public_network                     = undef,

#ceph.conf osd settings
  $osd_max_backfills                  = '1',
  $osd_recovery_max_active            = '1',

#RBD client settings
  $rbd_cache                          = true,
  $rbd_cache_writethrough_until_flush = true,

# RadosGW settings
  $rgw_host                           = $::hostname,
  $rgw_ip                             = '0.0.0.0',
  $rgw_port                           = '6780',
  $swift_endpoint_port                = '8080',
  $rgw_keyring_path                   = '/etc/ceph/keyring.radosgw.gateway',
  $rgw_socket_path                    = '/tmp/radosgw.sock',
  $rgw_frontends                      = 'fastcgi socket_port=9000 socket_host=127.0.0.1',
  $rgw_log_file                       = '/var/log/ceph/radosgw.log',
  $rgw_use_keystone                   = true,
  $rgw_use_pki                        = false,
  $rgw_keystone_url                   = "${cluster_node_address}:35357", #"fix my formatting.
  $rgw_keystone_admin_token           = undef,
  $rgw_keystone_token_cache_size      = '10',
  $rgw_keystone_accepted_roles        = '_member_, Member, admin, swiftoperator',
  $rgw_keystone_revocation_interval   = $::ceph::rgw_use_pki ? { false => 1000000, default => 60 },
  $rgw_s3_auth_use_keystone           = false,
  $rgw_data                           = '/var/lib/ceph/radosgw',
  $rgw_dns_name                       = "*.${::domain}",
  $rgw_print_continue                 = true,
  $rgw_nss_db_path                    = '/etc/ceph/nss',

  $rgw_large_pool_name                = '.rgw',
  $rgw_large_pool_pg_nums             = '512',

  $rgw_init_timeout                   = '360000',

# Cinder settings
  $volume_driver                      = 'cinder.volume.drivers.rbd.RBDDriver',
  $glance_api_version                 = '2',
  $cinder_user                        = 'volumes',
  $cinder_pool                        = 'volumes',
# TODO: generate rbd_secret_uuid
  $rbd_secret_uuid                    = 'a5d0dd94-57c4-ae55-ffe0-7e3732a24455',

# Cinder Backup settings
  $cinder_backup_user                 = 'backups',
  $cinder_backup_pool                 = 'backups',

# Glance settings
  $glance_backend                     = 'ceph',
  $glance_user                        = 'images',
  $glance_pool                        = 'images',
  $show_image_direct_url              = 'True',

# Compute settings
  $compute_user                       = 'compute',
  $compute_pool                       = 'compute',
  $libvirt_images_type                = 'rbd',
  $ephemeral_ceph                     = false,

# Log settings
  $use_syslog                         = false,
  $syslog_log_facility                = 'daemon',
  $syslog_log_level                   = 'info',
) {

  Exec {
    path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
    cwd  => '/root',
  }

  # the regex includes all roles that require ceph.conf
  if roles_include(['primary-controller', 'controller', 'ceph-mon', 'ceph-osd', 'compute', 'cinder']) {

    validate_array($mon_hosts)
    validate_array($mon_ip_addresses)

    include ceph::ssh
    include ceph::params
    include ceph::conf
    Class[['ceph::ssh', 'ceph::params']] -> Class['ceph::conf']
  }

  if roles_include(['primary-controller', 'controller', 'ceph-mon', 'ceph-osd']) {
    service { 'ceph':
      ensure     => 'running',
      name       => $::ceph::params::service_name,
      enable     => true,
      hasrestart => true,
      require    => Class['ceph::conf']
    }
    Package<| title == 'ceph' |> ~> Service['ceph']
    if !defined(Service['ceph']) {
      notify{ "Module ${module_name} cannot notify service ceph on packages update": }
    }
  }

  if roles_include(['primary-controller', 'controller', 'ceph-mon']) {
    include ceph::mon

    Class['ceph::conf'] -> Class['ceph::mon'] ->
    Service['ceph']

    if ($::ceph::use_rgw) {
      include ceph::radosgw
      Class['ceph::mon'] ->
      Class['ceph::radosgw']
      if defined(Class['::keystone']) {
        Class['::keystone'] -> Class['ceph::radosgw']
      }
      Ceph_conf <||> ~> Service['ceph']
    }
  }

  if roles_include('ceph-osd') {
    if ! empty($osd_devices) {
      include ceph::osds
      if roles_include(['ceph-mon']) {
        Class['ceph::mon'] -> Class['ceph::osds']
      }
      Class['ceph::conf'] -> Class['ceph::osds']
      Ceph_conf <||> ~> Service['ceph']

      # set the recommended value according: http://tracker.ceph.com/issues/10988
      sysctl::value { 'kernel.pid_max':
        value  => '4194303',
      }

      Sysctl::Value <| |> -> Service['ceph']
    }
  }

}
