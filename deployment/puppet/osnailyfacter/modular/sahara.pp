import 'globals.pp'

if $sahara_hash['enabled'] {
  class { 'sahara' :
    sahara_api_host            => $controller_node_public,

    sahara_db_password         => $sahara_hash['db_password'],
    sahara_db_host             => $controller_node_address,

    sahara_keystone_host       => $controller_node_address,
    sahara_keystone_user       => 'sahara',
    sahara_keystone_password   => $sahara_hash['user_password'],
    sahara_keystone_tenant     => 'services',
    sahara_auth_uri            => "http://${controller_node_address}:5000/v2.0/",
    sahara_identity_uri        => "http://${controller_node_address}:35357/",
    use_neutron                => $use_neutron,
    syslog_log_facility_sahara => $syslog_log_facility_sahara,
    debug                      => $debug,
    verbose                    => $verbose,
    use_syslog                 => $use_syslog,
    rpc_backend                => 'rabbit',
    enable_notifications       => $ceilometer_hash['enabled'],
    amqp_password              => $rabbit_hash['password'],
    amqp_user                  => $rabbit_hash['user'],
    amqp_port                  => $rabbitmq_bind_port,
    amqp_hosts                 => $amqp_hosts,
    rabbit_ha_queues           => $rabbit_ha_queues,
  }
}
