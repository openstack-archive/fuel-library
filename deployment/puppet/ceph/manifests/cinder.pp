#ceph::cinder will setup cinder parts if detected on the system
class ceph::cinder (
  $volume_driver      = $::ceph::volume_driver,
  $rbd_pool           = $::ceph::rbd_pool,
  $glance_api_version = $::ceph::glance_api_version,
  $rbd_user           = $::ceph::rbd_user,
  $rbd_secret_uuid    = $::ceph::rbd_secret_uuid,
) {
  if str2bool($::cinder_conf) {

    Cinder_config<||> ~> Service["${::ceph::params::service_cinder_volume}" ]
    File_line<||> ~> Service["${::ceph::params::service_cinder_volume}"]
    #TODO: this needs to be re-worked to follow https://wiki.openstack.org/wiki/Cinder-multi-backend
    cinder_config {
      'DEFAULT/volume_driver':           value => $volume_driver;
      'DEFAULT/rbd_pool':                value => $rbd_pool;
      'DEFAULT/glance_api_version':      value => $glance_api_version;
      'DEFAULT/rbd_user':                value => $rbd_user;
      'DEFAULT/rbd_secret_uuid':         value => $rbd_secret_uuid;
    }
     file { "${::ceph::params::service_cinder_volume_opts}":
      ensure => 'present',
    } -> file_line { 'cinder-volume.conf':
      path => "${::ceph::params::service_cinder_volume_opts}",
      line => 'export CEPH_ARGS="--id volumes"',
    }
    if ! defined(Class['cinder::volume']) {
      service { "${::ceph::params::service_cinder_volume}":
        ensure     => 'running',
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
      }
    }
    exec { 'Create keys for pool volumes':
      command => 'ceph auth get-or-create client.volumes > /etc/ceph/ceph.client.volumes.keyring',
      before  => File['/etc/ceph/ceph.client.volumes.keyring'],
      creates => '/etc/ceph/ceph.client.volumes.keyring',
      require => [Package['ceph'], Exec['ceph-deploy init config']],
      notify  => Service["${::ceph::params::service_cinder_volume}"],
      returns => 0,
    }
    file { '/etc/ceph/ceph.client.volumes.keyring':
      owner   => cinder,
      group   => cinder,
      require => Exec['Create keys for pool volumes'],
      mode    => '0600',
    }
  }
}
