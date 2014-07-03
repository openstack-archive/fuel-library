class nova::compute::mellanox (
  $physifc,
  $physnet = 'physnet2',
) {

  class { 'mellanox_openstack::compute_install_mlnx_plugin':
  }

  class { 'mellanox_openstack::eswitchd':
    physnet => $physnet,
    physifc => $physifc
  }

  class { 'mellanox_openstack::mlnx_agent':
    physnet => $physnet,
    physifc => $physifc
  }

}
