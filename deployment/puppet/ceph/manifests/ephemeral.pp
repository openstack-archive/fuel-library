# Enable RBD backend for ephemeral volumes
class ceph::ephemeral (
  $rbd_secret_uuid     = $::ceph::rbd_secret_uuid,
  $libvirt_images_type = $::ceph::libvirt_images_type,
  $pool                = $::ceph::compute_pool,
) {

  firewall {'117 allow tcp port range for migrations':
    chain   => 'INPUT',
    dport   => '49152-49215',
    proto   => 'tcp',
    action  => accept,
  }

  nova_config {
    'DEFAULT/libvirt_images_type':      value => $libvirt_images_type;
    'DEFAULT/libvirt_inject_key':       value => false;
    'DEFAULT/libvirt_inject_partition': value => '-2';
    'DEFAULT/libvirt_images_rbd_pool':  value => $pool;
    'DEFAULT/live_migration_flag':      value => 'VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_PERSIST_DEST';
  }
}
