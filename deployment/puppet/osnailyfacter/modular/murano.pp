import 'common/globals.pp'

if $murano_hash['enabled'] {

  class { 'murano' :
    murano_api_host          => $controller_node_address,

  # Controller adresses (for endpoints)
    admin_address            => $controller_node_address,
    public_address           => $controller_node_public,
    internal_address         => $controller_node_address,

  # Murano uses two RabbitMQ - one from OpenStack and another one installed on each controller.
  #   The second instance is used for communication with agents.
  #   * murano_rabbit_host provides address for murano-engine which communicates with this
  #    'separate' rabbitmq directly (without oslo.messaging).
  #   * murano_rabbit_ha_hosts / murano_rabbit_ha_queues are required for murano-api which
  #     communicates with 'system' RabbitMQ and uses oslo.messaging.
    murano_rabbit_host       => $controller_node_public,
    murano_rabbit_ha_hosts   => $amqp_hosts,

    murano_os_rabbit_userid  => $rabbit_hash['user'],
    murano_os_rabbit_passwd  => $rabbit_hash['password'],
    murano_own_rabbit_userid => 'murano',
    murano_own_rabbit_passwd => $heat_hash['rabbit_password'],

    murano_db_host           => $controller_node_address,
    murano_db_password       => $murano_hash['db_password'],

    murano_keystone_host     => $controller_node_address,
    murano_keystone_user     => 'murano',
    murano_keystone_password => $murano_hash['user_password'],
    murano_keystone_tenant   => 'services',

    use_neutron              => $use_neutron,

    use_syslog               => $use_syslog,
    debug                    => $debug,
    verbose                  => $verbose,
    syslog_log_facility      => $syslog_log_facility_murano,
  }

  Class['openstack::heat'] -> Class['murano']

}
