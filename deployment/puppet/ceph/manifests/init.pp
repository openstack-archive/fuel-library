# ceph configuration and resource relations

class ceph (
      # General settings
      $cluster_node_address = $::ipaddress, #This should be the cluster service address
      $primary_mon          = $::hostname, #This should be the first controller
      $mon_hosts            = nodes_with_roles($::fuel_settings['nodes'],
                                               ['primary-controller', 'controller', 'ceph-mon'],
                                               'name'),
      $mon_ip_addresses     = nodes_with_roles($::fuel_settings['nodes'],
                                               ['primary-controller', 'controller', 'ceph-mon'],
                                               'internal_address'),
      $osd_devices          = split($::osd_devices_list, ' '),
      $use_ssl              = false,
      $use_rgw              = false,

      # ceph.conf Global settings
      $auth_supported            = 'cephx',
      $osd_journal_size          = '2048',
      $osd_mkfs_type             = 'xfs',
      $osd_pool_default_size     = $::fuel_settings['storage']['osd_pool_size'],
      $osd_pool_default_min_size = '1',
      $osd_pool_default_pg_num   = $::fuel_settings['storage']['pg_num'],
      $osd_pool_default_pgp_num  = $::fuel_settings['storage']['pg_num'],
      $cluster_network           = $::fuel_settings['storage_network_range'],
      $public_network            = $::fuel_settings['management_network_range'],

      # RadosGW settings
      $rgw_host                         = $::hostname,
      $rgw_port                         = '6780',
      $swift_endpoint_port              = '8080',
      $rgw_keyring_path                 = '/etc/ceph/keyring.radosgw.gateway',
      $rgw_socket_path                  = '/tmp/radosgw.sock',
      $rgw_log_file                     = '/var/log/ceph/radosgw.log',
      $rgw_use_keystone                 = true,
      $rgw_use_pki                      = false,
      $rgw_keystone_url                 = "${cluster_node_address}:5000",
      $rgw_keystone_admin_token         = $::fuel_settings['keystone']['admin_token'],
      $rgw_keystone_token_cache_size    = '10',
      $rgw_keystone_accepted_roles      = '_member_, Member, admin, swiftoperator',
      $rgw_keystone_revocation_interval = $::ceph::rgw_use_pki ? { false => 1000000, default => 60},
      $rgw_data                         = '/var/lib/ceph/radosgw',
      $rgw_dns_name                     = "*.${::domain}",
      $rgw_print_continue               = true,
      $rgw_nss_db_path                  = '/etc/ceph/nss',

      # Keystone settings
      $rgw_pub_ip = $cluster_node_address,
      $rgw_adm_ip = $cluster_node_address,
      $rgw_int_ip = $cluster_node_address,

      # Cinder settings
      $volume_driver      = 'cinder.volume.drivers.rbd.RBDDriver',
      $glance_api_version = '2',
      $cinder_user        = 'volumes',
      $cinder_pool        = 'volumes',
      # TODO: generate rbd_secret_uuid
      $rbd_secret_uuid    = 'a5d0dd94-57c4-ae55-ffe0-7e3732a24455',

      # Glance settings
      $glance_backend        = 'ceph',
      $glance_user           = 'images',
      $glance_pool           = 'images',
      $show_image_direct_url = 'True',

      # Compute settings
      $compute_user          = 'compute',
      $compute_pool          = 'compute',
      $libvirt_images_type   = 'rbd',
) {

  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
         cwd  => '/root',
  }

  # Re-enable ceph::yum if not using a Fuel iso with Ceph packages
  #include ceph::yum

  if $::fuel_settings['role'] =~ /controller|ceph|compute|cinder/ {
    # the regex above includes all roles that require ceph.conf
    include ceph::ssh
    include ceph::params
    include ceph::conf
    Class[['ceph::ssh', 'ceph::params']] -> Class['ceph::conf']
  }

  if $::fuel_settings['role'] =~ /controller|ceph/ {
    service {'ceph':
      ensure  => 'running',
      enable  => true,
      require => Class['ceph::conf']
    }
    Package<| title == 'ceph' |> ~> Service<| title == 'ceph' |>
    if !defined(Service['ceph']) {
      notify{ "Module ${module_name} cannot notify service ceph on packages update": }
    }
  }

  case $::fuel_settings['role'] {
    'primary-controller', 'controller', 'ceph-mon': {
      include ceph::mon

      # DO NOT SPLIT ceph auth command lines! See http://tracker.ceph.com/issues/3279
      ceph::pool {$glance_pool:
        user          => $glance_user,
        acl           => "mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=${glance_pool}'",
        keyring_owner => 'glance',
      }

      ceph::pool {$cinder_pool:
        user          => $cinder_user,
        acl           => "mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=${cinder_pool}, allow rx pool=${glance_pool}'",
        keyring_owner => 'cinder',
      }

      Class['ceph::conf'] -> Class['ceph::mon'] ->
      Ceph::Pool[$glance_pool] -> Ceph::Pool[$cinder_pool] ->
      Service['ceph']

      if ($::ceph::use_rgw) {
        include ceph::radosgw
        Class['ceph::mon'] ->
        Class['ceph::radosgw'] ~>
        Service['ceph']

        Class['::keystone'] -> Class['ceph::radosgw']
      }
    }

    'ceph-osd': {
      if ! empty($osd_devices) {
        include ceph::osd
        Class['ceph::conf'] -> Class['ceph::osd'] ~> Service['ceph']
      }
    }

    'compute': {
      ceph::pool {$compute_pool:
        user          => $compute_user,
        acl           => "mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=${cinder_pool}, allow rx pool=${glance_pool}, allow rwx pool=${compute_pool}'",
        keyring_owner => 'nova',
      }

      include ceph::nova_compute

      if ($::fuel_settings['storage']['ephemeral_ceph']) {
        include ceph::ephemeral
        Class['ceph::conf'] -> Class['ceph::ephemeral'] ~>
        Service[$::ceph::params::service_nova_compute]
      }

      Class['ceph::conf'] ->
      Ceph::Pool[$compute_pool] ->
      Class['ceph::nova_compute'] ~>
      Service[$::ceph::params::service_nova_compute]
    }

    'ceph-mds': { include ceph::mds }

    default: {}
  }
}
