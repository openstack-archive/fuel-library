#
class nova::compute::neutron (
  $libvirt_vif_driver = 'nova.virt.libvirt.vif.LibvirtOpenVswitchDriver'
) {

  nova_config {
    'DEFAULT/libvirt_vif_driver':             value => $libvirt_vif_driver;
    'DEFAULT/libvirt_use_virtio_for_bridges': value => true;
  }
}
