notice('MODULAR: sahara.pp')

$sahara_hash                = hiera('sahara')
$controller_node_address    = hiera('controller_node_address')
$controller_node_public     = hiera('controller_node_public')
$public_ip                  = hiera('public_vip', $controller_node_public)
$management_ip              = hiera('management_vip', $controller_node_address)
$use_neutron                = hiera('use_neutron', false)
$syslog_log_facility_sahara = hiera('syslog_log_facility_sahara')
$ceilometer_hash            = hiera('ceilometer')
$debug                      = hiera('debug', false)
$verbose                    = hiera('verbose', true)
$use_syslog                 = hiera('use_syslog', true)
$rabbit_hash                = hiera('rabbit_hash')
$amqp_port                  = hiera('amqp_port')
$amqp_hosts                 = hiera('amqp_hosts')
$rabbit_ha_queues           = hiera('rabbit_ha_queues')
$deployment_mode            = hiera('deployment_mode')
$primary_controller         = hiera('primary_controller')

#################################################################

if $sahara_hash['enabled'] {

  ####### Disable upstart startup on install #######
  if($::operatingsystem == 'Ubuntu') {
    tweaks::ubuntu_service_override { 'sahara-api':
      package_name => 'sahara',
    }
  }

  class { 'sahara' :
    configure_keystone_auth    => $primary_controller,
    api_host                   => $public_ip,
    db_password                => $sahara_hash['db_password'],
    db_host                    => $management_ip,
    keystone_host              => $management_ip,
    keystone_user              => 'sahara',
    keystone_password          => $sahara_hash['user_password'],
    keystone_tenant            => 'services',
    auth_uri                   => "http://${management_ip}:5000/v2.0/",
    identity_uri               => "http://${management_ip}:35357/",
    use_neutron                => $use_neutron,
    syslog_log_facility        => $syslog_log_facility_sahara,
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

}

#########################

class mysql::server {}
class mysql::config {}

include mysql::server
include mysql::config

class openstack::firewall {}
include openstack::firewall

file { '/root/openrc' :}
