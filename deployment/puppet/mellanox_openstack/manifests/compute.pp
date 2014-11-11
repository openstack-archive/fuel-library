class mellanox_openstack::compute (
  $physifc,
  $physnet = 'physnet2',
) {

  class { 'mellanox_openstack::eswitchd' :
      physnet => $physnet,
      physifc => $physifc,
  }

  class { 'mellanox_openstack::agent' :
      physnet => $physnet,
      physifc => $physifc,
  }


  Service['libvirt'] ->
  Class['mellanox_openstack::eswitchd'] ->
  Class['mellanox_openstack::agent']

}
