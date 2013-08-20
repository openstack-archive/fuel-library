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
    }
    exec {'Copy configs':
      command => "scp -r ${nodes[-1]}:/etc/ceph/* /etc/ceph/",
      require => Package['ceph'],
      returns => [0,1],
    }
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
    File_line<||> ~> Service['cinder-volume']
    Cinder_config<||> ~> Service['cinder-volume']
    exec { 'Create keys for pool volumes':
      command => 'ceph auth get-or-create client.volumes > /etc/ceph/ceph.client.volumes.keyring',
      before  => File['/etc/ceph/ceph.client.volumes.keyring'],
      require => [Package['ceph'], Exec['Copy configs']],
      notify  => Service['cinder-volume'],
      returns => [0,1],
    }
    file { '/etc/ceph/ceph.client.volumes.keyring':
      owner   => cinder,
      group   => cinder,
      require => Exec['Create keys for pool volumes'],
    }
    service { 'cinder-volume':
      ensure => 'running',
      enable => true,
    }
  }
}
