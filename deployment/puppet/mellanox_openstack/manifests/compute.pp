class mellanox_openstack::compute(
  $physnet = 'physnet2',
  $physifc,
) {

  class { 'mellanox_openstack::compute_install_mlnx_plugin':
  }

  class { 'mellanox_openstack::eswitchd_config':
    physnet => $physnet,
    physifc => $physifc
  }

  class { 'mellanox_openstack::mlnx_agent_config':
    physnet => $physnet,
    physifc => $physifc
  }

  Class['mellanox_openstack::compute_install_mlnx_plugin'] -> Class['mellanox_openstack::eswitchd_config']
  Class['mellanox_openstack::compute_install_mlnx_plugin'] -> Class['mellanox_openstack::mlnx_agent_config']

}
