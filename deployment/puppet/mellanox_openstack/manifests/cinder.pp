class mellanox_openstack::cinder (
  $iser = false,
  $iser_ip_address,
) {
  if $iser {
    cinder_config { 'DEFAULT/volume_driver' :
      value => 'cinder.volume.drivers.lvm.LVMISERDriver'
    }
    cinder_config { 'DEFAULT/iser_ip_address' :
      value => $iser_ip_address
    }
  }
}
