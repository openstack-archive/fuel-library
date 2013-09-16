#ceph:glance will configure glance parts if present on the system
class ceph::glance (
  $default_store         = $::ceph::default_store,
  $rbd_store_user        = $::ceph::rbd_store_user,
  $rbd_store_pool        = $::ceph::rbd_store_pool,
  $show_image_direct_url = $::ceph::show_image_direct_url,
) {
  if str2bool($::glance_api_conf) {
    exec {'Copy config':
      command => "scp -r ${::ceph::primary_mon}:/etc/ceph/* /etc/ceph/",
      require => Package['ceph'],
      returns => 0,
    }
    if ! defined('glance::backend::ceph') {
      package {['python-ceph']:
        ensure  => latest,
      }
      glance_api_config {
        'DEFAULT/default_store':           value => $default_store;
        'DEFAULT/rbd_store_user':          value => $rbd_store_user;
        'DEFAULT/rbd_store_pool':          value => $rbd_store_pool;
        'DEFAULT/show_image_direct_url':   value => $show_image_direct_url;
      }~> Service["${::ceph::params::service_glance_api}"]
        service { "${::ceph::params::service_glance_api}":
          ensure     => 'running',
          enable     => true,
          hasstatus  => true,
          hasrestart => true,
        }
    }
    exec { 'Create keys for pool images':
      command => 'ceph auth get-or-create client.images > /etc/ceph/ceph.client.images.keyring',
      before  => File['/etc/ceph/ceph.client.images.keyring'],
      creates => '/etc/ceph/ceph.client.images.keyring',
      require => [Package['ceph'], Exec['Copy config']],
      notify  => Service["${::ceph::params::service_glance_api}"],
      returns => 0,
    }
    file { '/etc/ceph/ceph.client.images.keyring':
      owner   => glance,
      group   => glance,
      require => Exec['Create keys for pool images'],
      mode    => '0600',
    }
  }
}
