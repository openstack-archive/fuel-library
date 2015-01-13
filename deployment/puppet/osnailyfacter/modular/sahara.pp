$sahara_hash                = hiera('sahara')
$controller_node_address    = hiera('controller_node_address')
$controller_node_public     = hiera('controller_node_public')
$public_ip                  = hiera('public_vip', $controller_node_public)
$management_ip              = hiera('management_vip', $controller_node_address)
$use_neutron                = hiera('use_neutron')
$syslog_log_facility_sahara = hiera('syslog_log_facility_sahara')
$ceilometer_hash            = hiera('ceilometer')
$debug                      = hiera('debug', false)
$verbose                    = hiera('verbose', true)
$use_syslog                 = hiera('use_syslog', true)
$rabbit_hash                = hiera('rabbit')
$amqp_port                  = hiera('amqp_port')
$amqp_hosts                 = hiera('amqp_hosts')
$rabbit_ha_queue            = hiera('rabbit_ha_queues')
$deployment_mode            = hiera('deployment_mode')

#################################################################

if $sahara_hash['enabled'] {
  class { 'sahara' :
    sahara_api_host            => $public_ip,

    sahara_db_password         => $sahara_hash['db_password'],
    sahara_db_host             => $management_ip,

    sahara_keystone_host       => $management_ip,
    sahara_keystone_user       => 'sahara',
    sahara_keystone_password   => $sahara_hash['user_password'],
    sahara_keystone_tenant     => 'services',
    sahara_auth_uri            => "http://${management_ip}:5000/v2.0/",
    sahara_identity_uri        => "http://${management_ip}:35357/",
    use_neutron                => $use_neutron,
    syslog_log_facility_sahara => $syslog_log_facility_sahara,
    debug                      => $debug,
    verbose                    => $verbose,
    use_syslog                 => $use_syslog,
    enable_notifications       => $ceilometer_hash['enabled'],
    rpc_backend                => 'rabbit',
    amqp_password              => $rabbit_hash['password'],
    amqp_user                  => $rabbit_hash['user'],
    amqp_port                  => $amqp_port,
    amqp_hosts                 => $amqp_hosts,
    rabbit_ha_queues           => $rabbit_ha_queues,
  }

  if ($deployment_mode == 'ha') or ($deployment_mode == 'ha_compact') {
    include sahara_ha::api
  }
}
