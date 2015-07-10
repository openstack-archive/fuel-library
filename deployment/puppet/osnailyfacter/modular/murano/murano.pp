notice('MODULAR: murano.pp')

$murano_hash                = hiera('murano')
$murano_settings_hash       = hiera('murano_settings', {})
$openstack_version          = hiera('openstack_version')
$controller_node_address    = hiera('controller_node_address')
$controller_node_public     = hiera('controller_node_public')
$public_vip                 = hiera('public_vip', $controller_node_public)
$management_vip             = hiera('management_vip', $controller_node_address)
$service_endpoint           = hiera('service_endpoint')
$rabbit_ha_queues           = hiera('rabbit_ha_queues')
$rabbit_hash                = hiera('rabbit_hash')
$heat_hash                  = hiera('heat')
$use_neutron                = hiera('use_neutron', false)
$neutron_config             = hiera('neutron_config', {})
$debug                      = hiera('debug', false)
$verbose                    = hiera('verbose', true)
$use_syslog                 = hiera('use_syslog', false)
$syslog_log_facility_murano = hiera('syslog_log_facility_murano')
$primary_controller         = hiera('primary_controller')
$region                     = hiera('region', 'RegionOne')

#################################################################

if $murano_hash['enabled'] {

  if ! $use_neutron {
    fail 'Murano requires Neutron! Nova-Network is not supported!'
  }

  ####### Disable upstart startup on install #######
  if($::operatingsystem == 'Ubuntu') {
    tweaks::ubuntu_service_override { ['murano_api', 'murano_engine']:
      package_name => 'murano',
    }
  }

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
  if has_key($murano_settings_hash, 'murano_repo_url') {
    $murano_repo_url = $murano_settings_hash['murano_repo_url']
  } else {
    $murano_repo_url = 'http://storage.apps.openstack.org'
  }

  class { '::murano' :
    murano_package_name      => $murano_package_name,
    murano_api_host          => $management_vip,

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
    murano_rabbit_host       => $public_vip,
    murano_rabbit_ha_hosts   => hiera('amqp_hosts',''),
    murano_rabbit_ha_queues  => $rabbit_ha_queues,
    murano_os_rabbit_userid  => $rabbit_hash['user'],
    murano_os_rabbit_passwd  => $rabbit_hash['password'],
    murano_own_rabbit_userid => 'murano',
    murano_own_rabbit_passwd => $heat_hash['rabbit_password'],


    murano_db_host           => pick(hiera('database_vip'), hiera('management_vip')),
    murano_db_password       => $murano_hash['db_password'],

    murano_keystone_host     => $service_endpoint,
    murano_keystone_user     => 'murano',
    murano_keystone_password => $murano_hash['user_password'],
    murano_keystone_tenant   => 'services',
    region                   => $region,

    use_neutron              => $use_neutron,

    use_syslog               => $use_syslog,
    debug                    => $debug,
    verbose                  => $verbose,
    syslog_log_facility      => $syslog_log_facility_murano,

    primary_controller       => $primary_controller,
    external_network         => $external_network,

    murano_repo_url_string   => $murano_repo_url,
  }

  include ::tweaks::apache_wrappers

  if $primary_controller {
    $haproxy_stats_url = "http://${management_vip}:10000/;csv"

    haproxy_backend_status { 'murano' :
      name => 'murano',
      url  => $haproxy_stats_url,
    }

    Service<| title == 'murano_api'|> -> Haproxy_backend_status['murano'] -> Murano::Application_package <||>
  }

}

######################

class rabbitmq::service {}
class openstack::firewall {}
include rabbitmq::service
include openstack::firewall

file { '/etc/openstack-dashboard/local_settings' :}
