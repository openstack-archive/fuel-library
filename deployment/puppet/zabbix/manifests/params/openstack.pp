class zabbix::params::openstack {

  include zabbix::params

  $virtual_cluster_hostname = $zabbix::params::server_hostname
  $virtual_cluster_name = "OpenStackCluster${::deployment_id}"

  #monitoring VIP settings
  if ($::management_vip == undef) {
    $controller     = get_server_by_role(hiera('nodes'), ['primary-controller', 'controller'])
    $controller_ip  = $controller['internal_address']
    $keystone_vip   = $controller_ip
    $db_vip         = $controller_ip
    $nova_vip       = $controller_ip
    $glance_vip     = $controller_ip
    $cinder_vip     = $controller_ip
    $rabbit_vip     = $controller_ip
  } else {
    $keystone_vip   = $::management_vip
    $db_vip         = $::management_vip
    $nova_vip       = $::management_vip
    $glance_vip     = $::management_vip
    $cinder_vip     = $::management_vip
    $rabbit_vip     = $::management_vip
  }

  $access_hash          = hiera('access')
  $access_user          = $access_hash['user']
  $access_password      = $access_hash['password']
  $access_tenant        = $access_hash['tenant']

  $keystone_hash        = hiera('keystone')
  $keystone_db_password = $keystone_hash['db_password']

  $nova_hash            = hiera('nova')
  $nova_db_password     = $nova_hash['db_password']

  $cinder_hash          = hiera('cinder')
  $cinder_db_password   = $cinder_hash['db_password']

  $rabbit_hash          = hiera('rabbit')
  $rabbit_password      = $rabbit_hash['password']
}
