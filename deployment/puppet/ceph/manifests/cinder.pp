#ceph::cinder will setup cinder parts if detected on the system
class ceph::cinder (
  $volume_driver      = $::ceph::volume_driver,
  $rbd_pool           = $::ceph::rbd_pool,
  $glance_api_version = $::ceph::glance_api_version,
  $rbd_user           = $::ceph::rbd_user,
  $rbd_secret_uuid    = $::ceph::rbd_secret_uuid,
) {
  if defined(Class['openstack::cinder']){

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
    file {$::ceph::params::service_cinder_volume_opts:
      ensure => 'present',
    } -> file_line {'cinder-volume.conf':
      path => $::ceph::params::service_cinder_volume_opts,
      line => "export CEPH_ARGS='--id ${::ceph::cinder_pool}'",
    }
    if ! defined(Class['cinder::volume']) {
      service {$::ceph::params::service_cinder_volume:
        ensure     => 'running',
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
      }
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
      notify  => Service["${::ceph::params::service_cinder_volume}"],
      returns => 0,
    }

    file {$cinder_keyring:
      owner   => cinder,
      group   => cinder,
      require => Exec['Create keys for the Cinder pool'],
      mode    => '0600',
    }
  }
}
