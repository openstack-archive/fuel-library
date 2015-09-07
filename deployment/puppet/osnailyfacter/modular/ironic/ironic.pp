notice('MODULAR: ironic/ironic.pp')

$ironic_hash                = hiera_hash('ironic', {})
$nova_hash                  = hiera_hash('nova_hash', {})
$access_hash                = hiera_hash('access',{})
$public_vip                 = hiera('public_vip')
$management_vip             = hiera('management_vip')
$public_ssl_hash            = hiera('public_ssl')

$network_metadata           = hiera_hash('network_metadata', {})
$baremetal_vip              = $network_metadata['vips']['baremetal']['ipaddr']

$database_vip               = hiera('database_vip', $management_vip)
$keystone_endpoint          = hiera('keystone_endpoint', $management_vip)
$neutron_endpoint           = hiera('neutron_endpoint', $management_vip)
$glance_api_servers         = hiera('glance_api_servers', "${management_vip}:9292")
$debug                      = hiera('debug', false)
$verbose                    = hiera('verbose', true)
$use_syslog                 = hiera('use_syslog', true)
$syslog_log_facility_ironic = hiera('syslog_log_facility_ironic', 'LOG_USER')
$rabbit_hash                = hiera_hash('rabbit_hash', {})
$rabbit_ha_queues           = hiera('rabbit_ha_queues')
$amqp_hosts                 = hiera('amqp_hosts')
$rabbit_hosts               = split($amqp_hosts, ',')
$neutron_config             = hiera_hash('quantum_settings')

$db_host                    = pick($ironic_hash['db_host'], $database_vip)
$db_user                    = pick($ironic_hash['db_user'], 'ironic')
$db_name                    = pick($ironic_hash['db_name'], 'ironic')
$db_password                = pick($ironic_hash['db_password'], 'ironic')
$database_connection        = "mysql://${db_name}:${db_password}@${db_host}/${db_name}?charset=utf8&read_timeout=60"

$ironic_tenant              = pick($ironic_hash['tenant'],'services')
$ironic_user                = pick($ironic_hash['auth_name'],'ironic')
$ironic_user_password       = pick($ironic_hash['user_password'])

prepare_network_config(hiera('network_scheme', {}))

if $ironic_hash['enabled'] {
  class { 'ironic':
    verbose             => $verbose,
    debug               => $debug,
    enabled_drivers     => ['fuel_ssh', 'fuel_ipmitool'],
    rabbit_hosts        => $rabbit_hosts,
    rabbit_port         => 5673,
    rabbit_userid       => $rabbit_hash['user'],
    rabbit_password     => $rabbit_hash['password'],
    amqp_durable_queues => $rabbit_ha_queues,
    use_syslog          => $use_syslog,
    log_facility        => $syslog_log_facility_ironic,
    database_connection => $database_connection,
    glance_api_servers  => $glance_api_servers,
  }

  class { 'ironic::client': }

  class { 'ironic::api':
    host_ip           => get_network_role_property('ironic/api', 'ipaddr'),
    auth_host         => $keystone_endpoint,
    admin_tenant_name => $ironic_tenant,
    admin_user        => $ironic_user,
    admin_password    => $ironic_user_password,
    neutron_url       => "http://${neutron_endpoint}:9696",
  }

  firewall { '207 ironic-api' :
    dport   => '6385',
    proto   => 'tcp',
    action  => 'accept',
  }
}
