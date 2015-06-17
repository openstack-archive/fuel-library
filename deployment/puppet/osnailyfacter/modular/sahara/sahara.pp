notice('MODULAR: sahara.pp')

prepare_network_config(hiera('network_scheme', {}))

$access_admin               = hiera_hash('access', {})
$sahara_hash                = hiera_hash('sahara', {})
$rabbit_hash                = hiera_hash('rabbit', {})
$public_ssl_hash            = hiera('public_ssl')
$ceilometer_hash            = hiera_hash('ceilometer', {})
$primary_controller         = hiera('primary_controller')
$public_vip                 = hiera('public_vip')
$database_vip               = hiera('database_vip', undef)
$management_vip             = hiera('management_vip')
$use_neutron                = hiera('use_neutron', false)
$service_endpoint           = hiera('service_endpoint')
$syslog_log_facility_sahara = hiera('syslog_log_facility_sahara')
$debug                      = hiera('debug', false)
$verbose                    = hiera('verbose', true)
$use_syslog                 = hiera('use_syslog', true)
$rabbit_ha_queues           = hiera('rabbit_ha_queues')
$amqp_port                  = hiera('amqp_port')
$amqp_hosts                 = hiera('amqp_hosts')

#################################################################

$firewall_rule   = '201 sahara-api'
$api_bind_port   = '8386'
$api_bind_host   = get_network_role_property('sahara/api', 'ipaddr')
$api_workers     = '4'
$public_address = $public_ssl_hash['services'] ? {
  true    => $public_ssl_hash['hostname'],
  default => $public_vip,
}
$public_protocol = $public_ssl_hash['services'] ? {
  true    => 'https',
  default => 'http',
}
$sahara_user     = pick($sahara_hash['user'], 'sahara')
$sahara_password = pick($sahara_hash['user_password'])
$tenant          = pick($sahara_hash['tenant'], 'services')
$db_user         = pick($sahara_hash['db_user'], 'sahara')
$db_name         = pick($sahara_hash['db_name'], 'sahara')
$db_password     = pick($sahara_hash['db_password'])
$db_host         = pick($sahara_hash['db_host'], $database_vip)
$read_timeout    = '60'
$sql_connection  = "mysql://${db_user}:${db_password}@${db_host}/${db_name}?read_timeout=${read_timeout}"

####### Disable upstart startup on install #######
tweaks::ubuntu_service_override { 'sahara-api':
  package_name => 'sahara',
}

firewall { $firewall_rule :
  dport   => $api_bind_port,
  proto   => 'tcp',
  action  => 'accept',
}

class { 'sahara' :
  verbose             => $verbose,
  debug               => $debug,
  use_syslog          => $use_syslog,
  plugins             => [ 'ambari', 'cdh', 'mapr', 'spark', 'vanilla' ],
  log_facility        => $syslog_log_facility_sahara,
  database_connection => $sql_connection,
  auth_uri            => "${public_protocol}://${public_address}:5000/v2.0/",
  identity_uri        => "http://${service_endpoint}:35357/",
  rpc_backend         => 'rabbit',
  use_neutron         => $use_neutron,
  admin_user          => $sahara_user,
  admin_password      => $sahara_password,
  admin_tenant_name   => $tenant,
  rabbit_userid       => pick($rabbit_hash['user'], 'nova'),
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

$haproxy_stats_url = "http://${management_vip}:10000/;csv"

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
    auth_uri      => "${public_protocol}://${public_address}:5000/v2.0/",
  }

  Haproxy_backend_status['sahara'] -> Class['sahara_templates::create_templates']
}

Firewall[$firewall_rule] -> Class['sahara::api']
Service['sahara-api'] -> Haproxy_backend_status['sahara']

#########################

class openstack::firewall {}
include openstack::firewall
