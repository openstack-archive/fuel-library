# configures the Ceph RBD backend for Glance
class glance::backend::ceph(
  $default_store         = 'rbd',
  $rbd_store_user        = $::ceph::glance_user,
  $rbd_store_pool        = $::ceph::glance_pool,
  $show_image_direct_url = $::ceph::show_image_direct_url,
) inherits glance::api {

  package {'python-ceph':
    ensure => present,
  }

  glance_api_config {
    'DEFAULT/default_store':         value => $default_store;
    'DEFAULT/rbd_store_user':        value => $rbd_store_user;
    'DEFAULT/rbd_store_pool':        value => $rbd_store_pool;
    'DEFAULT/show_image_direct_url': value => $show_image_direct_url;
  }~> Service['glance-api']
}
