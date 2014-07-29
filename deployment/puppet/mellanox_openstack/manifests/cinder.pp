class mellanox_openstack::cinder (
  $iser = false,
) {
  if $iser {
    cinder_config { 'DEFAULT/volume_driver' :
      value => 'cinder.volume.drivers.lvm.LVMISERDriver'
    }
  }
}
