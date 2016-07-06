notice('MODULAR: ironic/ironic.pp')

$ironic_hash                = hiera_hash('ironic', {})
$public_vip                 = hiera('public_vip')
$management_vip             = hiera('management_vip')

$network_metadata           = hiera_hash('network_metadata', {})

$database_vip               = hiera('database_vip')
$keystone_endpoint          = hiera('service_endpoint')
$neutron_endpoint           = hiera('neutron_endpoint', $management_vip)
$glance_api_servers         = hiera('glance_api_servers', "${management_vip}:9292")
$debug                      = hiera('debug', false)
$verbose                    = hiera('verbose', true)
$default_log_levels         = hiera_hash('default_log_levels')
$use_syslog                 = hiera('use_syslog', true)
$syslog_log_facility_ironic = hiera('syslog_log_facility_ironic', 'LOG_USER')
$rabbit_hash                = hiera_hash('rabbit_hash', {})
$amqp_hosts                 = hiera('amqp_hosts')
$amqp_port                  = hiera('amqp_port', '5673')
$rabbit_hosts               = split($amqp_hosts, ',')
$neutron_config             = hiera_hash('quantum_settings')
$primary_controller         = hiera('primary_controller')
$amqp_durable_queues        = pick($ironic_hash['amqp_durable_queues'], false)

$memcached_servers          = hiera('memcached_servers')

$db_host                    = pick($ironic_hash['db_host'], $database_vip)
$db_user                    = pick($ironic_hash['db_user'], 'ironic')
$db_name                    = pick($ironic_hash['db_name'], 'ironic')
$db_password                = pick($ironic_hash['db_password'], 'ironic')
$database_connection        = "mysql://${db_name}:${db_password}@${db_host}/${db_name}?charset=utf8&read_timeout=60"

$ironic_tenant              = pick($ironic_hash['tenant'],'services')
$ironic_user                = pick($ironic_hash['auth_name'],'ironic')
$ironic_user_password       = pick($ironic_hash['user_password'],'ironic')

prepare_network_config(hiera_hash('network_scheme', {}))

$baremetal_vip = $network_metadata['vips']['baremetal']['ipaddr']

class { 'ironic':
  verbose              => $verbose,
  debug                => $debug,
  rabbit_hosts         => $rabbit_hosts,
  rabbit_port          => $amqp_port,
  rabbit_userid        => $rabbit_hash['user'],
  rabbit_password      => $rabbit_hash['password'],
  amqp_durable_queues  => $amqp_durable_queues,
  control_exchange     => 'ironic',
  use_syslog           => $use_syslog,
  log_facility         => $syslog_log_facility_ironic,
  database_connection  => $database_connection,
  database_max_retries => '-1',
  glance_api_servers   => $glance_api_servers,
  sync_db              => $primary_controller,
}

# TODO (iberezovskiy): Move to globals (as it is done for sahara)
# after new sync with upstream because of
# https://github.com/openstack/puppet-ironic/blob/master/manifests/init.pp#L261
if $default_log_levels {
  ironic_config {
    'DEFAULT/default_log_levels' :
      value => join(sort(join_keys_to_values($default_log_levels, '=')), ',');
  }
} else {
  ironic_config {
    'DEFAULT/default_log_levels' : ensure => absent;
  }
}
#

class { 'ironic::client': }

class { 'ironic::api':
  host_ip           => get_network_role_property('ironic/api', 'ipaddr'),
  auth_host         => $keystone_endpoint,
  admin_tenant_name => $ironic_tenant,
  admin_user        => $ironic_user,
  admin_password    => $ironic_user_password,
  neutron_url       => "http://${neutron_endpoint}:9696",
}

ironic_api_config {
  'keystone_authtoken/memcached_servers' : value => join(any2array($memcached_servers), ',');
}
