# Enable RBD backend for ephemeral volumes
class ceph::ephemeral (
  $rbd_secret_uuid     = $::ceph::rbd_secret_uuid,
  $libvirt_images_type = $::ceph::libvirt_images_type,
  $pool                = $::ceph::compute_pool,
) {

  nova_config {
    'DEFAULT/libvirt_images_type':      value => $libvirt_images_type;
    'DEFAULT/libvirt_inject_key':       value => false;
    'DEFAULT/libvirt_inject_partition': value => '-2';
    'DEFAULT/libvirt_images_rbd_pool':  value => $pool;
  }
}
