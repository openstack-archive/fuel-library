# == class: glance::backend::rbd
#
# configures the storage backend for glance
# as a rbd instance
#
# === parameters:
#
#  [*rbd_store_user*]
#    Optional.
#
#  [*rbd_store_pool*]
#    Optional. Default:'images'
#
#  [*rbd_store_ceph_conf*]
#    Optional. Default:'/etc/ceph/ceph.conf'
#
#  [*rbd_store_chunk_size*]
#    Optional. Default:'8'
#
#  [*show_image_direct_url*]
#    Optional. Enables direct COW from glance to rbd
#    DEPRECATED, use show_image_direct_url in glance::api
#
#  [*package_ensure*]
#      (optional) Desired ensure state of packages.
#      accepts latest or specific versions.
#      Defaults to present.
#

class glance::backend::rbd(
  $rbd_store_user         = undef,
  $rbd_store_ceph_conf    = '/etc/ceph/ceph.conf',
  $rbd_store_pool         = 'images',
  $rbd_store_chunk_size   = '8',
  $show_image_direct_url  = undef,
  $package_ensure         = 'present',
) {
  include ::glance::params

  if $show_image_direct_url {
    notice('parameter show_image_direct_url is deprecated, use parameter in glance::api')
  }

  glance_api_config {
    'glance_store/default_store':         value => 'rbd';
    'glance_store/rbd_store_ceph_conf':   value => $rbd_store_ceph_conf;
    'glance_store/rbd_store_user':        value => $rbd_store_user;
    'glance_store/rbd_store_pool':        value => $rbd_store_pool;
    'glance_store/rbd_store_chunk_size':  value => $rbd_store_chunk_size;
  }

  package { 'python-ceph':
    ensure => $package_ensure,
    name   => $::glance::params::pyceph_package_name,
  }

}
