# == Class: nova::compute::neutron
#
# Manage the network driver to use for compute guests
# This will use virtio for VM guests and the
# specified driver for the VIF
#
# === Parameters
#
# [*libvirt_vif_driver*]
#   (optional) The libvirt VIF driver to configure the VIFs.
#   Defaults to 'nova.virt.libvirt.vif.LibvirtGenericVIFDriver'.
#

class nova::compute::neutron (
  $libvirt_vif_driver = 'nova.virt.libvirt.vif.LibvirtGenericVIFDriver'
) {

  if $libvirt_vif_driver == 'nova.virt.libvirt.vif.LibvirtOpenVswitchDriver' {
    fail('nova.virt.libvirt.vif.LibvirtOpenVswitchDriver as vif_driver is removed from Icehouse')
  }

  nova_config {
    'libvirt/vif_driver': value => $libvirt_vif_driver;
  }
}
