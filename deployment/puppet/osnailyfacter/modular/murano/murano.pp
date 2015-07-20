notice('MODULAR: murano.pp')

$murano_hash                = hiera_hash('murano', {})
$rabbit_hash                = hiera_hash('rabbit_hash', {})
$heat_hash                  = hiera_hash('heat', {})
$neutron_config             = hiera_hash('neutron_config', {})
$primary_controller         = hiera('primary_controller')
$public_ip                  = hiera('public_vip')
$management_ip              = hiera('management_vip')
$internal_address           = hiera('internal_address')
$region                     = hiera('region', 'RegionOne')
$use_neutron                = hiera('use_neutron', false)
$service_endpoint           = hiera('service_endpoint', $management_ip)
$syslog_log_facility_murano = hiera('syslog_log_facility_murano')
$debug                      = hiera('debug', false)
$verbose                    = hiera('verbose', true)
$use_syslog                 = hiera('use_syslog', true)
$rabbit_ha_queues           = hiera('rabbit_ha_queues')
$amqp_port                  = hiera('amqp_port')
$amqp_hosts                 = hiera('amqp_hosts')
$public_ssl_hash            = hiera('public_ssl')

#################################################################

if $public_ssl {
  $public_protocol = 'https'
} else {
  $public_protocol = 'http'
}

$firewall_rule  = '202 murano-api'

$api_bind_port  = '8082'
$api_bind_host  = $internal_address

$murano_user    = pick($murano_hash['user'], 'murano')
$tenant         = pick($murano_hash['tenant'], 'services')
$public_url     = "${public_protocol}://${public_ip}:${api_bind_port}"
$admin_url      = "http://${service_endpoint}:${api_bind_port}"
$internal_url   = "http://${service_endpoint}:${api_bind_port}"
$db_user        = pick($murano_hash['db_user'], 'murano')
$db_name        = pick($murano_hash['db_name'], 'murano')
$db_password    = pick($murano_hash['db_password'])
$db_host        = pick($murano_hash['db_host'], $management_ip)
$read_timeout   = '60'
$sql_connection = "mysql://${db_user}:${db_password}@${db_host}/${db_name}?read_timeout=${read_timeout}"

####### Disable upstart startup on install #######
if($::operatingsystem == 'Ubuntu') {
  tweaks::ubuntu_service_override { ['murano-api', 'murano-engine']:
    package_name => 'murano',
  }
}

firewall { $firewall_rule :
  dport   => $api_bind_port,
  proto   => 'tcp',
  action  => 'accept',
}

class { 'murano::keystone::auth':
  password     => $murano_hash['user_password'],
  service_type => 'application_catalog',
  region       => $region,
  tenant       => $tenant,
  public_url   => $public_url,
  admin_url    => $admin_url,
  internal_url => $internal_url,
}

class { 'murano' :
  verbose             => $verbose,
  debug               => $debug,
  use_syslog          => $use_syslog,
  log_facility        => $syslog_log_facility_sahara,
  database_connection => $sql_connection,
  keystone_uri        => "http://${service_endpoint}:5000/v2.0/",
  keystone_username   => $murano_user,
  keystone_password   => $murano_hash['user_password'],
  keystone_tenant     => $tenant,
  identity_uri        => "http://$service_endpoint:35357/",
  use_neutron         => $use_neutron,
  rabbit_os_user      => $rabbit_hash['user'],
  rabbit_os_password  => $rabbit_hash['password'],
  rabbit_os_port      => $amqp_port,
  rabbit_os_host      => split($amqp_hosts, ','),
  rabbit_ha_queues    => $rabbit_ha_queues,
  rabbit_own_host     => $public_ip,
  rabbit_own_port     => '55572',
  rabbit_own_user     => 'murano',
  rabbit_own_password => $heat_hash['rabbit_password'],
  external_network    => get_ext_net_name($neutron_config['predefined_networks']),
}

class { 'murano::api':
  host        => $api_bind_host,
  port        => $api_bind_port,
}

class { 'murano::engine': }

class { 'murano::client': }

class { 'murano::dashboard': 
  api_url => $internal_url,
}

class { 'murano::rabbitmq':
  rabbit_user     => 'murano',
  rabbit_password => $heat_hash['rabbit_password'],
  rabbit_host     => $Public_ip,
  rabbit_port     => '55572',
}

$haproxy_stats_url = "http://${management_ip}:10000/;csv"

haproxy_backend_status { 'murano-api' :
  name => 'murano-api',
  url  => $haproxy_stats_url,
}

if $primary_controller {
  murano::application { 'io.murano' :
    os_tenant_name => $tenant,
    os_username    => $murano_user,
    os_password    => $murano_hash['user_password'],
    os_auth_url    => "http://${service_endpoint}:5000/v2.0/",
    os_region      => $region,
    mandatory      => true,
  }

  Service['murano-api'] -> Murano::Application<| mandatory == true |>
}

Firewall[$firewall_rule] -> Class['murano::api']
Service['murano-api'] -> Haproxy_backend_status['murano-api']

#########################

class openstack::firewall {}
include openstack::firewall