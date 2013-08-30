# Global settings
Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }

#hostnames MUST match either cluser_network, or public_network or
#ceph will not setup correctly.

#This permater defines the monitor nodes, these may be the same as the OSD's 
# if you want. There should be one or >=3
$mon_nodes = [
  'controller-3.domain.tld',
]

#This parameter defines the OSD storage nodes. One OSD will run per $osd_device
# per $osd_node. betweeen the two there must be two OSD processes
$osd_nodes = [
  'compute-1.domain.tld',
  'compute-2.domain.tld'
]

# Uncomment this line if you want to install RadosGW.
$rados_GW = 'fuel-controller-03.local.try'

# Uncomment this line if you want to install metadata server.
#$mds_server = 'fuel-controller-03.local.try'

$osd_devices = split($::osd_devices_list, "\n")
# This parameter defines which devices to aggregate into CEPH cluster.
# ALL THE DATA THAT RESIDES ON THESE DEVICES WILL BE LOST!
#$osd_devices = [ 'vdb2', 'vdc2' ]

# This parameter defines rbd pools for Cinder & Glance. It is not necessary to change.
$ceph_pools = [ 'volumes', 'images' ]

#TODO: need to resolve single node changes

# Determine CEPH and OpenStack nodes.
node 'default' {

  #RE-enable this if not using fuelweb iso with Cehp packages
  #include 'ceph::yum'
  include 'ceph::ssh'
  #TODO: this should be pulled back into existing modules for setting up ssh-key
  #TODO: OR need to at least generate the key
  include 'ntp'
  include 'ceph::deps'
  
  if $fqdn in $mon_nodes {
    firewall {'010 ceph-mon allow':
      chain => 'INPUT',
      dport => 6789,
      proto => 'tcp',
      action  => accept,
    } 
  }

  #TODO: These should only except traffic on the storage network 
  if $fqdn in $osd_nodes {
    firewall {'011 ceph-osd allow':
      chain => 'INPUT',
      dport => '6800-7100',
      proto => 'tcp',
      action  => accept,
    }
  }
  if $fqdn == $mon_nodes[-1] and !str2bool($::ceph_conf) {
    class { 'ceph::deploy':
      #Global settings 
      auth_supported                   => 'cephx',
      osd_journal_size                 => '2048',
      osd_mkfs_type                    => 'xfs',
      osd_pool_default_size            => '2',
      osd_pool_default_min_size        => '1',
      #TODO: calculate PG numbers
      osd_pool_default_pg_num          => '100',
      osd_pool_default_pgp_num         => '100',
      cluster_network                  => '10.0.0.0/24',
      public_network                   => '192.168.0.0/24',
      #RadosGW settings
      host                             => $::hostname,
      keyring_path                     => '/etc/ceph/keyring.radosgw.gateway',
      rgw_socket_path                  => '/tmp/radosgw.sock',
      log_file                         => '/var/log/ceph/radosgw.log',
      user                             => 'www-data',
      rgw_keystone_url                 => '10.0.0.223:5000',
      rgw_keystone_admin_token         => 'nova',
      rgw_keystone_token_cache_size    => '10',
      rgw_keystone_revocation_interval => '60',
      rgw_data                         => '/var/lib/ceph/rados',
      rgw_dns_name                     => $::hostname,
      rgw_print_continue               => 'false',
      nss_db_path                      => '/etc/ceph/nss',
    } -> Class[['ceph::glance',
                'ceph::cinder',
                'ceph::nova_compute',
                'ceph::keystone']]
    #All classes that should run after ceph::deploy should be below
  }
  if $fqdn == $rados_GW {
    ceph::radosgw {"${::hostname}":
      require => Class['ceph::deploy']
    }
  }
  class { 'ceph::glance':
    default_store         => 'rbd',
    rbd_store_user        => 'images',
    rbd_store_pool        => 'images',
    show_image_direct_url => 'True',
  }
  class { 'ceph::cinder':
    volume_driver         => 'cinder.volume.drivers.rbd.RBDDriver',
    rbd_pool              => 'volumes',
    glance_api_version    => '2',
    rbd_user              => 'volumes',
    #TODO: generate rbd_secret_uuid
    rbd_secret_uuid       => 'a5d0dd94-57c4-ae55-ffe0-7e3732a24455',
  }
  class { 'ceph::nova_compute': }
  class { 'ceph::keystone': #{ "Keystone":
    pub_ip => "${rados_GW}",
    adm_ip => "${rados_GW}",
    int_ip => "${rados_GW}",
  }
}
