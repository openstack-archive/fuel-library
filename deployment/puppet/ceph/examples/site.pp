# Global settings
Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }

# This parameters defines nodes for CEPH cluster.
# The last node in this case is the master node of CEPH cluster and should be deployed last.
$ceph_nodes = [
  'fuel-ceph-01.local.try',
  'fuel-ceph-02.local.try'
]

# Uncomment this line if you want to install RadosGW.
$rados_GW = 'fuel-controller-03.local.try'

# Uncomment this line if you want to install metadata server.
$mds_server = 'fuel-controller-03.local.try'

# This parameter defines which devices to aggregate into CEPH cluster.
# ALL THE DATA THAT RESIDES ON THESE DEVICES WILL BE LOST!
$osd_devices = [ 'vdb2', 'vdc2' ]

# This parameter defines rbd pools for Cinder & Glance. It is not necessary to change.
$ceph_pools = [ 'volumes', 'images' ]

#TODO: need resolve firewall dep.
#TODO: need to seperate mon and osd list
#TODO: need to resolve single node changes

#TODO: need to remove this hack for epel repos
class {'openstack::mirantis_repos':
  type=> 'default',
}

file {'/etc/yum.repos.d/openstack-koji-fuel-grizzly.repo':
  ensure => absent,
}

# Determine CEPH and OpenStack nodes.
node 'default' {

  include 'ceph::yum'
  #TODO: this needs to be pulled back into mirantis mirrors
  include 'ceph::ssh'
  #TODO: this should be pulled back into existing modules for settingup ssh-key
  #TODO: OR need to atleast generate the key
  include 'ntp'

  package { ['ceph', 'redhat-lsb-core']:
    ensure => latest,
  }
  #TODO: RHEL suoders needs Defaults !requiretty
  if $fqdn == $ceph_nodes[-1] and !str2bool($::ceph_conf) {
    class { 'ceph::deploy':
      auth_supported   => 'cephx',
      osd_journal_size => '2048',
      osd_mkfs_type    => 'xfs',
    }
    package {['ceph-deploy', 'python-pushy']:
      ensure  => latest,
      #require => Class['apt::update']
    }
    class { 'ceph::deploy':
      #Global settings 
      auth_supported                   => 'cephx',
      osd_journal_size                 => '2048',
      osd_mkfs_type                    => 'xfs',
      osd_pool_default_size            => '2',
      osd_pool_default_min_size        => '1',
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
    }
  }
  if $fqdn == $rados_GW {
    ceph::radosgw {"${::hostname}":
      require => Class['apt::update', 'ceph::deploy']
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
    rbd_secret_uuid       => 'a5d0dd94-57c4-ae55-ffe0-7e3732a24455',
  }
  class { 'ceph::nova_compute': }
  ceph::keystone { "Keystone":
    pub_ip => "${rados_GW}",
    adm_ip => "${rados_GW}",
    int_ip => "${rados_GW}",
  }
}
