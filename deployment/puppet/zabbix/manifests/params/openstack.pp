class zabbix::params::openstack {

  include zabbix::params

  $virtual_cluster_hostname = $zabbix::params::server_hostname
  $virtual_cluster_name = "OpenStackCluster${::deployment_id}"

  #monitoring VIP settings
  if ($::management_vip == undef) {
    $controller     = get_server_by_role($::fuel_settings['nodes'], ['primary-controller', 'controller'])
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

  $access_user          = $::fuel_settings['access']['user']
  $access_password      = $::fuel_settings['access']['password']
  $access_tenant        = $::fuel_settings['access']['tenant']
  $keystone_db_password = $::fuel_settings['keystone']['db_password']
  $nova_db_password     = $::fuel_settings['nova']['db_password']
  $cinder_db_password   = $::fuel_settings['cinder']['db_password']
  $rabbit_password      = $::fuel_settings['rabbit']['password']
}
