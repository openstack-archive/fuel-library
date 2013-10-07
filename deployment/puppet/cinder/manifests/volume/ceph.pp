class cinder::volume::ceph (
  $volume_driver      = $::ceph::volume_driver,
  $rbd_pool           = $::ceph::rbd_pool,
  $glance_api_version = $::ceph::glance_api_version,
  $rbd_user           = $::ceph::rbd_user,
  $rbd_secret_uuid    = $::ceph::rbd_secret_uuid,
) {

  require ::ceph

  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
         cwd  => '/root',
  }

  Cinder_config<||> ~> Service['cinder-volume']
  File_line<||> ~> Service['cinder-volume']
  # TODO: this needs to be re-worked to follow https://wiki.openstack.org/wiki/Cinder-multi-backend
  cinder_config {
    'DEFAULT/volume_driver':           value => $volume_driver;
    'DEFAULT/rbd_pool':                value => $rbd_pool;
    'DEFAULT/glance_api_version':      value => $glance_api_version;
    'DEFAULT/rbd_user':                value => $rbd_user;
    'DEFAULT/rbd_secret_uuid':         value => $rbd_secret_uuid;
  }
  # TODO: convert to cinder params
  file {$::ceph::params::service_cinder_volume_opts:
    ensure => 'present',
  } -> file_line {'cinder-volume.conf':
    path => $::ceph::params::service_cinder_volume_opts,
    line => "export CEPH_ARGS='--id ${::ceph::cinder_pool}'",
  }

  exec {'Create Cinder Ceph client ACL':
    # DO NOT SPLIT ceph auth command lines! See http://tracker.ceph.com/issues/3279
    command   => "ceph auth get-or-create client.${::ceph::cinder_pool} mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=${::ceph::cinder_pool}, allow rx pool=${::ceph::glance_pool}'",
    logoutput => true,
  }

  $cinder_keyring = "/etc/ceph/ceph.client.${::ceph::cinder_pool}.keyring"
  exec {'Create keys for the Cinder pool':
    command => "ceph auth get-or-create client.${::ceph::cinder_pool} > ${cinder_keyring}",
    before  => File[$cinder_keyring],
    creates => $cinder_keyring,
    require => Exec['Create Cinder Ceph client ACL'],
    notify  => Service['cinder-volume'],
    returns => 0,
  }

  file {$cinder_keyring:
    owner   => cinder,
    group   => cinder,
    require => Exec['Create keys for the Cinder pool'],
    mode    => '0600',
  }
}