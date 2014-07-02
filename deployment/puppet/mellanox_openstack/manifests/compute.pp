class mellanox_openstack::compute (
  $physnet = 'physnet2',
  $physifc,
) {

  class { 'mellanox_openstack::eswitchd' :
      physnet => $physnet,
      physifc => $physifc,
  }

  class { 'mellanox_openstack::agent' :
      physnet => $physnet,
      physifc => $physifc,
  }

  class { 'mellanox_openstack::mlnxvif' :}

  Class['mellanox_openstack::mlnxvif'] ->
  Class['mellanox_openstack::eswitchd'] ->
  Class['mellanox_openstack::mlnx_agent']

}
