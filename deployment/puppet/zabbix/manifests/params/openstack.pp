class zabbix::params::openstack {

  include zabbix::params

  $virtual_cluster_name = "OpenStackCluster${::deployment_id}"

  #monitoring VIP settings
  if ($::fuel_settings['management_vip'] == undef) {
    $controller     = get_server_by_role($::fuel_settings['nodes'], ['primary-controller', 'controller'])
    $controller_ip  = $controller['internal_address']
    $keystone_vip   = $controller_ip
    $db_vip         = $controller_ip
    $nova_vip       = $controller_ip
    $glance_vip     = $controller_ip
    $cinder_vip     = $controller_ip
    $rabbit_vip     = $controller_ip
  } else {
    $keystone_vip   = $::fuel_settings['management_vip']
    $db_vip         = $::fuel_settings['management_vip']
    $nova_vip       = $::fuel_settings['management_vip']
    $glance_vip     = $::fuel_settings['management_vip']
    $cinder_vip     = $::fuel_settings['management_vip']
    $rabbit_vip     = $::fuel_settings['management_vip']
  }

  case $::operatingsystem {
    'Ubuntu', 'Debian': {
      $rabbitmq_service_name = 'rabbitmq-server'
    }
    'CentOS', 'RedHat': {
      $rabbitmq_service_name = 'rabbitmq-server'
    }
  }

  $access_user          = $::fuel_settings['access']['user']
  $access_password      = $::fuel_settings['access']['password']
  $access_tenant        = $::fuel_settings['access']['tenant']
  $keystone_db_password = $::fuel_settings['keystone']['db_password']
  $nova_db_password     = $::fuel_settings['nova']['db_password']
  $cinder_db_password   = $::fuel_settings['cinder']['db_password']
  $rabbit_password      = $::fuel_settings['rabbit']['password']
  if !$::fuel_settings['rabbit']['user'] {
    $rabbit_user = 'nova'
  } else {
    $rabbit_user = $::fuel_settings['rabbit']['user']
  }
}
