class ceph::cinder (
  $volume_driver,
  $rbd_pool,
  $glance_api_version,
  $rbd_user,
  $rbd_secret_uuid,
) {
  if str2bool($::cinder_conf) {
    package {['ceph-common']:
      ensure  => latest,
      require => Class['apt::update']
    }
    exec {'Copy configs':
      command => "scp -r ${nodes[-1]}:/etc/ceph/* /etc/ceph/",
      require => Package['ceph'],
      returns => [0,1],
    }

    Cinder_config<||> ~> Service['cinder-volume']
    File_line<||> ~> Service['cinder-volume']

    cinder_config {
      'DEFAULT/volume_driver':           value => $volume_driver;
      'DEFAULT/rbd_pool':                value => $rbd_pool;
      'DEFAULT/glance_api_version':      value => $glance_api_version;
      'DEFAULT/rbd_user':                value => $rbd_user;
      'DEFAULT/rbd_secret_uuid':         value => $rbd_secret_uuid;
    }
    file_line { 'cinder-volume.conf':
      path => '/etc/init/cinder-volume.conf',
      line => 'env CEPH_ARGS="--id volumes"',
    }
    service { 'cinder-volume':
      ensure     => "running",
      enable     => true,
      hasstatus  => true,
      hasrestart => true,
    }
    exec { 'Create keys for pool volumes':
      command => 'ceph auth get-or-create client.volumes > /etc/ceph/ceph.client.volumes.keyring',
      before  => File['/etc/ceph/ceph.client.volumes.keyring'],
      require => [Package['ceph'], Exec['Copy configs']],
      returns => [0,1],
    }
    file { '/etc/ceph/ceph.client.volumes.keyring':
      owner  => cinder,
      group  => cinder,
      require => Exec['Create keys for pool volumes'],
    }
  }
}
