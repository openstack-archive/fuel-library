$murano_hash                = hiera('murano')
$openstack_version          = hiera('openstack_version')
$controller_node_address    = hiera('controller_node_address')
$controller_node_public     = hiera('controller_node_public')
$public_ip                  = hiera('public_vip', $controller_node_public)
$management_ip              = hiera('management_vip', $controller_node_address)
$amqp_hosts                 = hiera('amqp_hosts')
$rabbit_ha_queues           = hiera('rabbit_ha_queues')
$rabbit_hash                = hiera('rabbit')
$heat_hash                  = hiera('heat')
$use_neutron                = hiera('use_neutron')
$neutron_config             = hiera('neutron_config', {})
$debug                      = hiera('debug', false)
$verbose                    = hiera('verbose', true)
$syslog_log_facility_murano = hiera('syslog_log_facility_murano')
$primary_controller         = hiera('primary_controller')

#################################################################

if $murano_hash['enabled'] {

  #NOTE(mattymo): Backward compatibility for Icehouse
  case $openstack_version {
    /201[1-3]\./: {
      fail("Unsupported OpenStack version: ${openstack_version}")
    }
    /2014\.1\./: {
      $murano_package_name              = 'murano-api'
    }
    default: {
      $murano_package_name              = 'murano'
    }
  }

  $external_network = get_ext_net_name($neutron_config['predefined_networks'])

  class { 'murano' :
    murano_package_name      => $murano_package_name,
    murano_api_host          => $management_ip,

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
    murano_rabbit_host       => $public_ip,
    murano_rabbit_ha_hosts   => $amqp_hosts,
    murano_rabbit_ha_queues  => $rabbit_ha_queues,
    murano_os_rabbit_userid  => $rabbit_hash['user'],
    murano_os_rabbit_passwd  => $rabbit_hash['password'],
    murano_own_rabbit_userid => 'murano',
    murano_own_rabbit_passwd => $heat_hash['rabbit_password'],


    murano_db_host           => $management_ip,
    murano_db_password       => $murano_hash['db_password'],

    murano_keystone_host     => $management_ip,
    murano_keystone_user     => 'murano',
    murano_keystone_password => $murano_hash['user_password'],
    murano_keystone_tenant   => 'services',

    use_neutron              => $use_neutron,

    use_syslog               => $use_syslog,
    debug                    => $debug,
    verbose                  => $verbose,
    syslog_log_facility      => $syslog_log_facility_murano,

    primary_controller       => $primary_controller,
    external_network         => $external_network,
  }

}

######################

class mysql::server {}
class mysql::config {}
class rabbitmq::service {}
class openstack::firewall {}
include mysql::server
include mysql::config
include rabbitmq::service
include openstack::firewall

file { '/etc/openstack-dashboard/local_settings' :}
