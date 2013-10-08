# ceph configuration and resource relations

class ceph (
      # General settings
      $cluster_node_address             = $::ipaddress, #This should be the cluster service address
      $primary_mon                      = $::hostname, #This should be the first controller
      $cinder_pool                      = 'volumes',
      $glance_pool                      = 'images',
      $osd_devices                      = split($::osd_devices_list, ' '),
      $use_ssl                          = false,
      $use_rgw                          = false,

      # ceph.conf Global settings
      $auth_supported                   = 'cephx',
      $osd_journal_size                 = '2048',
      $osd_mkfs_type                    = 'xfs',
      $osd_pool_default_size            = '2',
      $osd_pool_default_min_size        = '1',
      # TODO: calculate PG numbers
      $osd_pool_default_pg_num          = '100',
      $osd_pool_default_pgp_num         = '100',
      $cluster_network                  = $::fuel_settings['storage_network_range'],
      $public_network                   = $::fuel_settings['management_network_range'],

      # RadosGW settings
      $rgw_host                         = $::fqdn,
      $rgw_port                         = '6780',
      $rgw_keyring_path                 = '/etc/ceph/keyring.radosgw.gateway',
      $rgw_socket_path                  = '/tmp/radosgw.sock',
      $rgw_log_file                     = '/var/log/ceph/radosgw.log',
      $rgw_keystone_url                 = "${cluster_node_address}:5000",
      $rgw_keystone_admin_token         = $::fuel_settings['keystone']['admin_token'],
      $rgw_keystone_token_cache_size    = '10',
      $rgw_keystone_accepted_roles      = '_member_, Member, admin, swiftoperator',
      $rgw_keystone_revocation_interval = '60',
      $rgw_data                         = '/var/lib/ceph/radosgw',
      $rgw_dns_name                     = "*.${::domain}",
      $rgw_print_continue               = 'false',
      $rgw_nss_db_path                  = '/etc/ceph/nss',

      # Keystone settings
      $rgw_pub_ip                       = $cluster_node_address,
      $rgw_adm_ip                       = $cluster_node_address,
      $rgw_int_ip                       = $cluster_node_address,

      # Cinder settings
      $volume_driver                    = 'cinder.volume.drivers.rbd.RBDDriver',
      $rbd_pool                         = 'volumes',
      $glance_api_version               = '2',
      $rbd_user                         = 'volumes',
      # TODO: generate rbd_secret_uuid
      $rbd_secret_uuid                  = 'a5d0dd94-57c4-ae55-ffe0-7e3732a24455',

      # Glance settings
      $glance_backend                   = 'ceph',
      $rbd_store_user                   = 'images',
      $rbd_store_pool                   = 'images',
      $show_image_direct_url            = 'True',
) {

  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
         cwd  => '/root',
  }

  # Re-enable ceph::yum if not using a Fuel iso with Ceph packages
  #include ceph::yum

  include ceph::ssh
  include ceph::params
  include ceph::conf
  Class[['ceph::ssh', 'ceph::params']] -> Class['ceph::conf']

  if $::fuel_settings['role'] =~ /controller|ceph/ {
    service {'ceph':
      ensure => 'running',
      enable => true,
    }
  }

  case $::fuel_settings['role'] {
    'primary-controller', 'controller', 'ceph-mon': {
      include ceph::mon
      Class['ceph::conf'] ->
      Class['ceph::mon']  ->
      Service['ceph']

      if ($::ceph::use_rgw) {
        include ceph::libnss, ceph::keystone, ceph::radosgw
        Class['ceph::mon'] ->
        Class['ceph::libnss'] ->
        Class[['ceph::keystone', 'ceph::radosgw']] ~>
        Service['ceph']
      }
    }

    'ceph-osd': {
      if ! empty($osd_devices) {
        include ceph::osd
        Class['ceph::conf'] -> Class['ceph::osd'] -> Service['ceph']
      }
    }

    'compute': {
      include ceph::nova_compute
      Class['ceph::conf'] ->
      Class['ceph::nova_compute'] ~>
      Service[$::ceph::params::service_nova_compute]
    }

    'ceph-mds': { include ceph::mds }

    default: {}
  }
}
