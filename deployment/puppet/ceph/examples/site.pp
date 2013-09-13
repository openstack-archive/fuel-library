# Global settings
Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }

# Hostnames MUST match either cluster_network, or public_network or
# ceph will not setup correctly.

# Uncomment this line if you want to install RadosGW.
#$rados_GW = 'fuel-controller-03.local.try'

# Uncomment this line if you want to install metadata server.
#$mds_server = 'fuel-controller-03.local.try'

$primary_mon = 'controller-1.domain.tld'
$cluster_network = '10.0.0.0/24'
$public_network = '192.168.0.0/24'
$osd_devices = split($::osd_devices_list, " ")
$cluster_node_address = '10.0.0.3'

node 'default' {
  class {'ceph':
      #General settings
      cluster_node_address             => $cluster_node_address,
      primary_mon                      => $primary_mon,
      ceph_pools                       => [ 'volumes', 'images' ],
      osd_devices                      => split($::osd_devices_list, " "),
      #ceph.conf Global settings
      auth_supported                   => 'cephx',
      osd_journal_size                 => '2048',
      osd_mkfs_type                    => 'xfs',
      osd_pool_default_size            => '2',
      osd_pool_default_min_size        => '1',
      #TODO: calculate PG numbers
      osd_pool_default_pg_num          => '100',
      osd_pool_default_pgp_num         => '100',
      cluster_network                  => "${cluster_network}",
      public_network                   => "${public_network}",
      #RadosGW settings
      host                             => $::hostname,
      keyring_path                     => '/etc/ceph/keyring.radosgw.gateway',
      rgw_socket_path                  => '/tmp/radosgw.sock',
      log_file                         => '/var/log/ceph/radosgw.log',
      user                             => 'www-data',
      rgw_keystone_url                 => "${controller_node_address}:5000",
      rgw_keystone_admin_token         => 'nova',
      rgw_keystone_token_cache_size    => '10',
      rgw_keystone_accepted_roles      => undef, #TODO: find a default value for this
      rgw_keystone_revocation_interval => '60',
      rgw_data                         => '/var/lib/ceph/rados',
      rgw_dns_name                     => $::hostname,
      rgw_print_continue               => 'false',
      nss_db_path                      => '/etc/ceph/nss',
      #Cinder settings
      volume_driver                    => 'cinder.volume.drivers.rbd.RBDDriver',
      rbd_pool                         => 'volumes',
      glance_api_version               => '2',
      rbd_user                         => 'volumes',
      #TODO: generate rbd_secret_uuid
      rbd_secret_uuid                  => 'a5d0dd94-57c4-ae55-ffe0-7e3732a24455',
      #Glance settings
      default_store                    => 'rbd',
      rbd_store_user                   => 'images',
      rbd_store_pool                   => 'images',
      show_image_direct_url            => 'True',
      #Keystone settings
      rgw_pub_ip                       => "${cluster_node_address}",
      rgw_adm_ip                       => "${cluster_node_address}",
      rgw_int_ip                       => "${cluster_node_address}",
  }
}
