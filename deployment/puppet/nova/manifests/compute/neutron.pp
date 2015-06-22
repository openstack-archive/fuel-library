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
# [*force_snat_range*]
#  (optional) Force SNAT rule to specified network for nova-network
#  Default to 0.0.0.0/0
#  Due to architecture constraints in nova_config, it's not possible to setup
#  more than one SNAT rule though initial parameter is MultiStrOpt
class nova::compute::neutron (
  $libvirt_vif_driver = 'nova.virt.libvirt.vif.LibvirtGenericVIFDriver',
  $force_snat_range   = '0.0.0.0/0',
) {

  if $libvirt_vif_driver == 'nova.virt.libvirt.vif.LibvirtOpenVswitchDriver' {
    fail('nova.virt.libvirt.vif.LibvirtOpenVswitchDriver as vif_driver is removed from Icehouse')
  }

  nova_config {
    'libvirt/vif_driver': value => $libvirt_vif_driver;
  }

  if $libvirt_vif_driver == 'nova.virt.libvirt.vif.LibvirtGenericVIFDriver' and $force_snat_range {
    # Validate ip and mask for force_snat_range
    $force_snat_range_array = split($force_snat_range, '/')
    if is_ip_address($force_snat_range_array[0]) and is_integer($force_snat_range_array[1])  {
      nova_config {
        'DEFAULT/force_snat_range': value => $force_snat_range;
      }
    } else {
      fail('force_snat_range should be IPv4 or IPv6 CIDR notation')
    }
  } else {
    nova_config {
      'DEFAULT/force_snat_range': ensure => absent;
    }
  }

}
