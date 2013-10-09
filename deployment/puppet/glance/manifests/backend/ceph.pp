#configures the glance blacked for ceph (rbd) driver
class glance::backend::ceph(
  $default_store         = 'rbd',
  $rbd_store_user        = $::ceph::rbd_store_user,
  $rbd_store_pool        = $::ceph::rbd_store_pool,
  $show_image_direct_url = $::ceph::show_image_direct_url,
) inherits glance::api {

  require ::ceph

  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
         cwd  => '/root',
  }

  package {'python-ceph':
    ensure => latest,
  }

  glance_api_config {
    'DEFAULT/default_store':           value => $default_store;
    'DEFAULT/rbd_store_user':          value => $rbd_store_user;
    'DEFAULT/rbd_store_pool':          value => $rbd_store_pool;
    'DEFAULT/show_image_direct_url':   value => $show_image_direct_url;
  }~> Service['glance-api']

  exec {'Create Glance Ceph client ACL':
    # DO NOT SPLIT ceph auth command lines! See http://tracker.ceph.com/issues/3279
    command   => "ceph auth get-or-create client.${::ceph::glance_pool} mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=${::ceph::glance_pool}'",
    logoutput => true,
  }

  $glance_keyring = "/etc/ceph/ceph.client.${::ceph::glance_pool}.keyring"
  exec {'Create keys for the Glance pool':
    command => "ceph auth get-or-create client.${::ceph::glance_pool} > ${$glance_keyring}",
    before  => File[$glance_keyring],
    creates => $glance_keyring,
    require => Exec['Create Glance Ceph client ACL'],
    notify  => Service['glance-api'],
    returns => 0,
  }

  file {$glance_keyring:
    owner   => glance,
    group   => glance,
    require => Exec['Create keys for the Glance pool'],
    mode    => '0600',
  }
}
