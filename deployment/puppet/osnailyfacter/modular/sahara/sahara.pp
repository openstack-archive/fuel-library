notice('MODULAR: sahara.pp')

$access_admin               = hiera_hash('access', {})
$sahara_hash                = hiera_hash('sahara', {})
$rabbit_hash                = hiera_hash('rabbit_hash', {})
$ceilometer_hash            = hiera_hash('ceilometer', {})
$primary_controller         = hiera('primary_controller')
$public_ip                  = hiera('public_vip')
$management_ip              = hiera('management_vip')
$internal_address           = hiera('internal_address')
$region                     = hiera('region', 'RegionOne')
$use_neutron                = hiera('use_neutron', false)
$syslog_log_facility_sahara = hiera('syslog_log_facility_sahara')
$debug                      = hiera('debug', false)
$verbose                    = hiera('verbose', true)
$use_syslog                 = hiera('use_syslog', true)
$rabbit_ha_queues           = hiera('rabbit_ha_queues')
$amqp_port                  = hiera('amqp_port')
$amqp_hosts                 = hiera('amqp_hosts')

#################################################################

if $sahara_hash['enabled'] {

  $firewall_rule  = '201 sahara-api'
  $api_bind_port  = '8386'
  $api_bind_host  = $internal_address
  $api_workers    = '4'
  $sahara_user    = pick($sahara_hash['user'], 'sahara')
  $tenant         = pick($sahara_hash['tenant'], 'services')
  $public_url     = "http://${public_ip}:${api_bind_port}/v1.1/%(tenant_id)s"
  $admin_url      = "http://${management_ip}:${api_bind_port}/v1.1/%(tenant_id)s"
  $internal_url   = "http://${internal_address}:${api_bind_port}/v1.1/%(tenant_id)s"
  $db_user        = pick($sahara_hash['db_user'], 'sahara')
  $db_name        = pick($sahara_hash['db_name'], 'sahara')
  $db_password    = pick($sahara_hash['db_password'])
  $db_host        = pick($sahara_hash['db_host'], $management_ip)
  $read_timeout   = '60'
  $sql_connection = "mysql://${db_user}:${db_password}@${db_host}/${db_name}?read_timeout=${read_timeout}"

  ####### Disable upstart startup on install #######
  if($::operatingsystem == 'Ubuntu') {
    tweaks::ubuntu_service_override { 'sahara-api':
      package_name => 'sahara',
    }
  }

  firewall { $firewall_rule :
    dport   => $api_bind_port,
    proto   => 'tcp',
    action  => 'accept',
  }

  class { 'sahara::keystone::auth':
    password     => $sahara_hash['user_password'],
    service_type => 'data_processing',
    region       => $region,
    tenant       => $tenant,
    public_url   => $public_url,
    admin_url    => $admin_url,
    internal_url => $internal_url,
  }

  class { 'sahara' :
    verbose             => $verbose,
    debug               => $debug,
    use_syslog          => $use_syslog,
    log_facility        => $syslog_log_facility_sahara,
    database_connection => $sql_connection,
    auth_uri            => "http://${management_ip}:5000/v2.0/",
    identity_uri        => "http://${management_ip}:35357/",
    rpc_backend         => 'rabbit',
    use_neutron         => $use_neutron,
    admin_user          => $sahara_user,
    admin_password      => $sahara_hash['user_password'],
    admin_tenant_name   => $tenant,
    rabbit_userid       => $rabbit_hash['user'],
    rabbit_password     => $rabbit_hash['password'],
    rabbit_ha_queues    => $rabbit_ha_queues,
    rabbit_port         => $amqp_port,
    rabbit_hosts        => split($amqp_hosts, ',')
  }

  class { 'sahara::api':
    api_workers => $api_workers,
    host        => $api_bind_host,
    port        => $api_bind_port,
  }

  class { 'sahara::engine':
    infrastructure_engine => 'heat',
  }

  class { 'sahara::client': }

  if $ceilometer_hash['enabled'] {
    class { '::sahara::notify':
      enable_notifications => true,
    }
  }

  $haproxy_stats_url = "http://${management_ip}:10000/;csv"

  haproxy_backend_status { 'sahara' :
    name => 'sahara',
    url  => $haproxy_stats_url,
  }

  if $primary_controller {
    class { 'sahara_templates::create_templates' :
      use_neutron   => $use_neutron,
      auth_user     => $access_admin['user'],
      auth_password => $access_admin['password'],
      auth_tenant   => $access_admin['tenant'],
      auth_uri      => "http://${management_ip}:5000/v2.0/",
    }

    Haproxy_backend_status['sahara'] -> Class['sahara_templates::create_templates']
  }

  Firewall[$firewall_rule] -> Class['sahara::api']
  Service['sahara-api'] -> Haproxy_backend_status['sahara']
}

#########################

class openstack::firewall {}
include openstack::firewall
