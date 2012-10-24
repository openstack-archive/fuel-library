class nova::compute::quantum (

){

  nova_config {
    'DEFAULT/libvirt_vif_driver':             value => 'nova.virt.libvirt.vif.LibvirtOpenVswitchDriver';
    #'libvirt_vif_driver':             value => 'nova.virt.libvirt.vif.LibvirtHybirdOVSBridgeDriver';
    'DEFAULT/libvirt_use_virtio_for_bridges': value => 'True';
  }
}
