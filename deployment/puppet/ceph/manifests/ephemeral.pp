# Enable RBD backend for ephemeral volumes
class ceph::ephemeral (
  $rbd_secret_uuid     = $::ceph::rbd_secret_uuid,
  $libvirt_images_type = $::ceph::libvirt_images_type,
  $pool                = $::ceph::compute_pool,
) {

  nova_config {
    'libvirt/images_type':      value => $libvirt_images_type;
    'libvirt/inject_key':       value => false;
    'libvirt/inject_partition': value => '-2';
    'libvirt/images_rbd_pool':  value => $pool;
  }
}
