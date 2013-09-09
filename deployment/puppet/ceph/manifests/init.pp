class ceph (
      #General settings
      $cluster_node_address             = $::ipaddress, #This should be the cluster service address
      $primary_mon                      = $::hostname, #This should be the first controller
      $ceph_pools                       = [ 'volumes', 'images' ],
      $osd_devices                      = split($::osd_devices_list, "\n"),
      #ceph.conf Global settings
      $auth_supported                   = 'cephx',
      $osd_journal_size                 = '2048',
      $osd_mkfs_type                    = 'xfs',
      $osd_pool_default_size            = '2',
      $osd_pool_default_min_size        = '1',
      #TODO: calculate PG numbers
      $osd_pool_default_pg_num          = '100',
      $osd_pool_default_pgp_num         = '100',
      $cluster_network                  = "$::storage_network_range",
      $public_network                   = "$::management_network_range",
      #RadosGW settings
      $host                             = $::hostname,
      $keyring_path                     = '/etc/ceph/keyring.radosgw.gateway',
      $rgw_socket_path                  = '/tmp/radosgw.sock',
      $log_file                         = '/var/log/ceph/radosgw.log',
      $user                             = 'www-data',
      $rgw_keystone_url                 = "${cluster_node_address}:5000",
      $rgw_keystone_admin_token         = 'nova',
      $rgw_keystone_token_cache_size    = '10',
      $rgw_keystone_accepted_roles      = undef, #TODO: find a default value for this
      $rgw_keystone_revocation_interval = '60',
      $rgw_data                         = '/var/lib/ceph/rados',
      $rgw_dns_name                     = $::hostname,
      $rgw_print_continue               = 'false',
      $nss_db_path                      = '/etc/ceph/nss',
      #Cinder settings
      $volume_driver                    = 'cinder.volume.drivers.rbd.RBDDriver',
      $rbd_pool                         = 'volumes',
      $glance_api_version               = '2',
      $rbd_user                         = 'volumes',
      #TODO: generate rbd_secret_uuid
      $rbd_secret_uuid                  = 'a5d0dd94-57c4-ae55-ffe0-7e3732a24455',
      #Glance settings
      $default_store                    = 'rbd',
      $rbd_store_user                   = 'images',
      $rbd_store_pool                   = 'images',
      $show_image_direct_url            = 'True',
      #Keystone settings
      $rgw_pub_ip                       = "${cluster_node_address}",
      $rgw_adm_ip                       = "${cluster_node_address}",
      $rgw_int_ip                       = "${cluster_node_address}",
) {

  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }

  #RE-enable this if not using fuelweb iso with Cehp packages
  #include 'ceph::yum'
  include 'ceph::params'
  include 'ceph::ssh'
  #TODO: this should be pulled back into existing modules for setting up ssh-key
  #TODO: OR need to at least generate the key

  #Prepare nodes for futher actions
  #TODO: add ceph service
  if $::hostname == $::ceph::primary_mon {
    exec { 'ceph-deploy init config':
      command => "ceph-deploy new ${::hostname}:${::public_address}",
      require => Package['ceph-deploy', 'ceph'],
      logoutput => true,
    }
  } else {
    exec {'ceph-deploy init config':
      command => "ceph-deploy --overwrite-conf config pull ${::ceph::primary_mon} && \
                  ceph-deploy gatherkeys ${::ceph::primary_mon} && \
                  ceph-deploy --overwrite-conf config push ${::hostname}",
      require => Package['ceph-deploy', 'ceph'],
      creates => ['/root/ceph.conf',
                  '/etc/ceph.conf',
                  '/root/ceph.bootstrap-mds.keyring',
                  '/root/ceph.bootstrap-osd.keyring',
                  '/root/ceph.admin.keyring',
                  '/root/ceph.mon.keyring'
                 ]
    }
  }

  case $::role {
    'primary-controller', 'controller', 'ceph-monitor': {
      include ceph::glance, ceph::cinder, ceph::nova_compute
      class {'ceph::mon':
      } -> Class[['ceph::glance',
                  'ceph::cinder',
                  'ceph::nova_compute',
                  #'ceph::keystone', #ceph::yeystone is currently disabled
                ]]
      #include ceph::keystone #Keystone is currently disabled
    }
    #TODO: remove cinder from this list.
    #This will still NOOP on cinder if $::osd_device_list is empty
    'ceph-osd', 'cinder': {
      class {'ceph::osd': }
    }
    'ceph-mds': {
      class {'ceph::deploy': }
    }
    'compute': {
      class {'ceph::nova_compute': }
    }
    default: {
      #TODO: this is probably too aggressive
      include ceph::cinder, ceph::nova_compute
    }
  }

}
