# Global settings
Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }

# This parameters defines nodes for CEPH cluster.
# The last node in this case is the master node of CEPH cluster and should be deployed last.
$nodes = [
  'fuel-ceph-01.local.try',
  'fuel-ceph-02.local.try'
]

# Uncomment this line if you want to install metadata server.
# $mds_server = 'fuel-ceph-02.local.try'

# This parameter defines which devices to aggregate into CEPH cluster.
# ALL THE DATA THAT RESIDES ON THESE DEVICES WILL BE LOST!
$osd_devices = [ 'vdb', 'vdc' ]

# This parameter defines rbd pools for Cinder & Glance. It is not necessary to change.
$pools = [ 'volumes', 'images' ]


# Determine CEPH and OpenStack nodes.
node 'default' {

  include 'ceph::apt'
  include 'ceph::ssh'
  include 'ntp'

  package { 'ceph':
    ensure => latest,
  }
  if $fqdn == $nodes[-1] and !str2bool($::ceph_conf) {
    class { 'ceph::deploy':
      auth_supported   => 'cephx',
      osd_journal_size => '2048',
      osd_mkfs_type    => 'xfs',
    }
    package {['ceph-deploy']:
      ensure  => latest,
      require => Class['apt::update']
    }
  }
  class { 'ceph::glance':
    default_store         => 'rbd',
    rbd_store_user        => 'images',
    rbd_store_pool        => 'images',
    show_image_direct_url => 'True'
  }
  class { 'ceph::cinder':
    volume_driver         => 'cinder.volume.drivers.rbd.RBDDriver',
    rbd_pool              => 'volumes',
    glance_api_version    => '2',
    rbd_user              => 'volumes',
    rbd_secret_uuid       => 'a5d0dd94-57c4-ae55-ffe0-7e3732a24455'
  }
  class { 'ceph::nova_compute': }
}
