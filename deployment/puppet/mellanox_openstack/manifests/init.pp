class mellanox_openstack {

  Class['mellanox_openstack::ofed_recompile'] {
    before => [
      Class['mellanox_openstack::agent'],
      Class['mellanox_openstack::cinder'],
      Class['mellanox_openstack::compute'],
      Class['mellanox_openstack::controller'],
      Class['mellanox_openstack::eswitchd'],
      Class['mellanox_openstack::iser_rename'],
      Class['mellanox_openstack::mlnxvif'],
      Class['mellanox_openstack::openibd'],
    ]
  }
}
