notice('MODULAR: ironic.pp')

$ironic_hash                = hiera_hash('ironic', {})
$nova_hash                  = hiera_hash('nova', {})
$access_hash                = hiera_hash('access',{})
$public_vip                 = hiera('public_vip')
$management_vip             = hiera('management_vip')
$service_endpoint           = hiera('service_endpoint', $management_vip)
$database_vip               = hiera('database_vip', $service_endpoint)
$keystone_endpoint          = hiera('keystone_endpoint', $service_endpoint)
$neutron_endpoint           = hiera('neutron_endpoint', $service_endpoint)
$glance_api_servers         = hiera('glance_api_servers', "${service_endpoint}:9292")
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

$region                     = hiera('region', 'RegionOne')
$public_url                 = "http://${public_vip}:6385"
$admin_url                  = "http://${management_vip}:6385"
$internal_url               = "http://${management_vip}:6385"

$os_auth_url                = "http://${keystone_endpoint}:5000/v2.0"
$ironic_tenant              = pick($ironic_hash['tenant'],'services')
$ironic_user                = pick($ironic_hash['user'],'ironic')
$ironic_user_password       = $ironic_hash['user_password']
$ironic_swift_tempurl_key   = $ironic_hash['swift_tempurl_key']

$swift_cmd_prefix           = "/usr/bin/swift --os-auth-url ${os_auth_url} --os-tenant-name ${ironic_tenant} --os-username ${ironic_user} --os-password ${ironic_user_password}"

if $ironic_hash['enabled'] {
  class { 'ironic':
    verbose                     => $verbose,
    debug                       => $debug,
    enabled_drivers             => ['fuel_ssh'],
    rabbit_hosts                => $rabbit_hosts,
    rabbit_port                 => 5673,
    rabbit_userid               => $rabbit_hash['user'],
    rabbit_password             => $rabbit_hash['password'],
    amqp_durable_queues         => $rabbit_ha_queues,
    use_syslog                  => $use_syslog,
    log_facility                => $syslog_log_facility_ironic,
    database_connection         => $database_connection,
    glance_api_servers          => $glance_api_servers,
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

  class { 'ironic::keystone::auth':
    password            => $ironic_user_password,
    region              => $region,
    public_url          => $public_url,
    internal_url        => $internal_url,
    admin_url           => $admin_url,
  }

  firewall { '207 ironic-api' :
    dport   => '6385',
    proto   => 'tcp',
    action  => 'accept',
  }

  $neutron_net = $neutron_config['predefined_networks']['baremetal']
  openstack::network::create_network{'baremetal':
    netdata => $neutron_net,
  } ->
  neutron_router_interface { "router04:baremetal__subnet":
    ensure => present,
  }

  exec { 'ironic-register-swift-tempurl-key':
    command => "${swift_cmd_prefix} post -m 'Temp-URL-Key:${ironic_swift_tempurl_key}'",
  }
}

