class mellanox_openstack::compute (
  $physnet = 'physnet2',
  $physifc,
  $plugin,
) {

  class { 'mellanox_openstack::eswitchd' :
    physnet => $physnet,
    physifc => $physifc,
  }

  class { 'mellanox_openstack::mlnx_agent' :
    physnet => $physnet,
    physifc => $physifc,
  }

  Class['mellanox_openstack::eswitchd'] ->
  Class['mellanox_openstack::mlnx_agent']

  if $plugin == 'ethernet' {
    nova_config {
      'DEFAULT/compute_driver':  value => 'nova.virt.libvirt.driver.LibvirtDriver';
      'libvirt/vif_driver':      value => 'mlnxvif.vif.MlxEthVIFDriver';
    }
  }

}
