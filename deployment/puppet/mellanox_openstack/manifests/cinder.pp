class mellanox_openstack::cinder (
  $iser = false,
) {
  if $iser {
    Cinder_config <| title == 'DEFAULT/volume_driver' |> {
      value => 'cinder.volume.drivers.lvm.LVMISERDriver'
    }
  }
}
