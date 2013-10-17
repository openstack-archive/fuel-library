# Global settings
Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }

# Hostnames MUST match either cluster_network, or public_network or
# ceph will not setup correctly.

# primary_mon defines the node from which ceph-deploy will pull it's config
# from in any following nodes. All nodes must have a ssh-key and root (or sudo)
# access to this host. ceph-deploy new will only be run from here.
$primary_mon = 'controller-1.domain.tld'

# public_network is necessary to add monitors atomically, the monitor nodes will
# also bind to this address.
$public_network = '192.168.0.0/24'

# cluster_network is necessary to ensure that osd's bind to the expected interface.
$cluster_network = '10.0.0.0/24'

# osd_devices is used in ceph::osd to activate the disk and join it to the 
# cluster.
# it may be <device_name|mounted_path>[:journal_device|journal_path]...
$osd_devices = split($::osd_devices_list, " ")

########
#RadosGW
########
# set use_rgw to configure RadosGW items
$use_rgw = false

# rgw_port, if you are running other services on this web server you need to
# run rgw on an alternate port, default is 6780
#$rgw_port = 6780

# rgw_use_keystone will configure the keystone parts
#$rgw_use_keystone = true

#rgw_use_pki if true, attempt to sign the keystone certs and enable PKI
# token verification. If false, will defalt to values that should work with UUID
# this requires keystone.conf to use token_format = PKI and 
# keystone-manage pki_setup to have been run. This also assumes that rados is
# being installed on the keystone server, otherwise you will need to move the
# keys yourself into /etc/keystone/ssl.
#$rgw_use_pki = false

# rgw_keystone_url is the ip and port for the keystone server, this will work
# on management or admin url's (internal:5000 or internal:35357)
#$rgw_keystone_url = 192.168.1.20:5000

# rgw_keystone_admin_token will be the token to perform admin functions in
# keystone. This is commonly inside /root/openrc on controllers
#$rgw_keystone_admin_token = 'CPj09fj'


#These are the settings for the keystone endpoint. They should point to your
# radosgw node, or to a vip for it. These may all be the same value for RadosGW
#$rgw_pub_ip => 192.168.1.20,
#$rgw_adm_ip => 192.168.1.20,
#$rgw_int_ip => 192.168.1.20,

node 'default' {
  class {'ceph':
      # General settings
      cluster_node_address => $cluster_node_address, #This should be the cluster service address
      primary_mon          => $primary_mon, #This should be the first controller
      osd_devices          => split($::osd_devices_list, ' '),
      use_ssl              => false,
      use_rgw              => $use_rgw,

      # ceph.conf Global settings
      auth_supported            => 'cephx',
      osd_journal_size          => '2048',
      osd_mkfs_type             => 'xfs',
      osd_pool_default_size     => '2',
      osd_pool_default_min_size => '1',
      # TODO: calculate PG numbers
      osd_pool_default_pg_num   => '100',
      osd_pool_default_pgp_num  => '100',
      cluster_network           => $cluster_network,
      public_network            => $public_network,

      # RadosGW settings
      rgw_host                         => $::osfamily ? {'Debian'=> $::hostname, default => $::fqdn},
      rgw_port                         => $rgw_port,
      rgw_keyring_path                 => '/etc/ceph/keyring.radosgw.gateway',
      rgw_socket_path                  => '/tmp/radosgw.sock',
      rgw_log_file                     => '/var/log/ceph/radosgw.log',
      rgw_use_keystone                 => true,
      rgw_use_pki                      => false,
      rgw_keystone_url                 => $rgw_keystone_url,
      rgw_keystone_admin_token         => $rgw_keystone_admin_token,
      rgw_keystone_token_cache_size    => '10',
      rgw_keystone_accepted_roles      => '_member_, Member, admin, swiftoperator',
      rgw_keystone_revocation_interval => $::ceph::rgw_use_pki ? { false => 1000000, default => 60 },
      rgw_data                         => '/var/lib/ceph/radosgw',
      rgw_dns_name                     => "*.${::domain}",
      rgw_print_continue               => 'false',
      rgw_nss_db_path                  => '/etc/ceph/nss',

      # Keystone settings
      rgw_pub_ip => $rgw_pub_ip,
      rgw_adm_ip => $rgw_adm_ip,
      rgw_int_ip => $rgw_int_ip,

      # Cinder settings
      volume_driver      => 'cinder.volume.drivers.rbd.RBDDriver',
      glance_api_version => '2',
      cinder_user        => 'volumes',
      cinder_pool        => 'volumes',
      # TODO: generate rbd_secret_uuid
      rbd_secret_uuid    => 'a5d0dd94-57c4-ae55-ffe0-7e3732a24455',

      # Glance settings
      glance_backend        => 'ceph',
      glance_user           => 'images',
      glance_pool           => 'images',
      show_image_direct_url => 'True',
  }
}
