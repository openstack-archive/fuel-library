class openstack_tasks::aodh::aodh {

  notice('MODULAR: aodh/aodh.pp')

  $notification_topics = 'notifications'

  $rabbit_ha_queues = hiera('rabbit_ha_queues')

  $rabbit_hash     = hiera_hash('rabbit', {})

  $kombu_compression   = hiera('kombu_compression', $::os_service_default)

  prepare_network_config(hiera_hash('network_scheme', {}))

  $aodh_hash            = hiera_hash('aodh', {})
  $aodh_user_name       = pick($aodh_hash['user'], 'aodh')
  $aodh_user_password   = $aodh_hash['user_password']
  $service_name         = pick($aodh_hash['service'], 'aodh')
  $region               = pick($aodh_hash['region'], hiera('region', 'RegionOne'))
  $tenant               = pick($aodh_hash['tenant'], 'services')

  $debug   = pick($aodh_hash['debug'], hiera('debug', false))

  $database_vip = hiera('database_vip')

  $db_type          = pick($aodh_hash['db_type'], 'mysql+pymysql')
  $db_name          = pick($aodh_hash['db_name'], 'aodh')
  $db_user          = pick($aodh_hash['db_user'], 'aodh')
  $db_password      = $aodh_hash['db_password']
  $db_host          = pick($aodh_hash['db_host'], $database_vip)
  $db_collate       = pick($aodh_hash['db_collate'], 'utf8_general_ci')
  $db_charset       = pick($aodh_hash['db_charset'], 'utf8')
  $db_allowed_hosts = pick($aodh_hash['db_allowed_hosts'], '%')

  if $::os_package_type == 'debian' {
      $extra_params = { 'charset' => 'utf8', 'read_timeout' => 60 }
    } else {
      $extra_params = { 'charset' => 'utf8' }
  }
  $database_connection = os_database_connection({
    'dialect'  => $db_type,
    'host'     => $db_host,
    'database' => $db_name,
    'username' => $db_user,
    'password' => $db_password,
    'extra'    => $extra_params
  })

  $transport_url = hiera('transport_url','rabbit://guest:password@127.0.0.1:5672/')

  $external_lb = hiera('external_lb', false)

  $public_vip      = hiera('public_vip')
  $public_ssl_hash = hiera('public_ssl')
  $public_address  = $public_ssl_hash['services'] ? {
    true    => $public_ssl_hash['hostname'],
    default => $public_vip,
  }
  $public_protocol = $public_ssl_hash['services'] ? {
    true    => 'https',
    default => 'http',
  }

  $management_vip     = hiera('management_vip')
  $service_endpoint   = hiera('service_endpoint')
  $aodh_api_bind_port = '8042'
  $aodh_api_bind_host = get_network_role_property('aodh/api', 'ipaddr')
  $public_url         = "${public_protocol}://${public_address}:${aodh_api_bind_port}"

  $ssl_hash    = hiera_hash('use_ssl', {})
  $public_cert = get_ssl_property($ssl_hash, $public_ssl_hash, 'keystone', 'public', 'path', [''])

  $memcached_servers = hiera('memcached_servers')
  $local_memcached_server = hiera('local_memcached_server')

  $internal_auth_protocol = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
  $internal_auth_address  = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [$management_vip])
  $keystone_auth_uri      = "${internal_auth_protocol}://${internal_auth_address}:5000/v2.0"
  $keystone_auth_url      = "${internal_auth_protocol}://${internal_auth_address}:35357/"

  # backwards compatibility with previous ceilometer configuration around alarm
  # history ttl
  $default_ceilometer_hash = {
    'alarm_history_time_to_live' => '604800',
  }
  $ceilometer_hash   = hiera_hash('ceilometer', $default_ceilometer_hash)
  $alarm_history_ttl = pick($aodh_hash['alarm_history_time_to_live'], $ceilometer_hash['alarm_history_time_to_live'])
  $ha_mode           = pick($ceilometer_hash['ha_mode'], true)

  $rabbit_heartbeat_timeout_threshold = pick($aodh_hash['rabbit_heartbeat_timeout_threshold'], $rabbit_hash['heartbeat_timeout_threshold'], 60)
  $rabbit_heartbeat_rate              = pick($aodh_hash['rabbit_heartbeat_rate'], $rabbit_hash['rabbit_heartbeat_rate'], 2)

#as $ssl default value in aodh::wsgi::apache is true and
#we use SSL at HAproxy, but not the API host we should set 'false'
#value for $ssl.
  $ssl = false

  #################################################################

  class { '::aodh':
    debug                              => $debug,
    notification_topics                => $notification_topics,
    rabbit_ha_queues                   => $rabbit_ha_queues,
    database_connection                => $database_connection,
    default_transport_url              => $transport_url,
    alarm_history_time_to_live         => $alarm_history_ttl,
    rabbit_heartbeat_timeout_threshold => $rabbit_heartbeat_timeout_threshold,
    rabbit_heartbeat_rate              => $rabbit_heartbeat_rate,
    kombu_compression                  => $kombu_compression,
  }

  class { '::aodh::auth':
    auth_url           => $keystone_auth_uri,
    auth_user          => $aodh_user_name,
    auth_password      => $aodh_user_password,
    auth_region        => $region,
    auth_tenant_name   => $tenant,
    auth_cacert        => $public_cert,
    auth_endpoint_type => 'internalURL',
  }

  aodh_config { 'notification/store_events': value => true; }

  if $debug {
    aodh_config { 'api/pecan_debug': value => true; }
  } else {
    aodh_config { 'api/pecan_debug': value => false; }
  }

  class { '::aodh::db::sync':
    user => $db_user,
  }

  class { '::aodh::keystone::authtoken':
    username          => $aodh_user_name,
    password          => $aodh_user_password,
    project_name      => $tenant,
    auth_uri          => $keystone_auth_uri,
    auth_url          => $keystone_auth_url,
    memcached_servers => $local_memcached_server,
  }

  class { '::aodh::api':
    enabled           => true,
    package_ensure    => 'present',
    service_name      => 'httpd',
  }

  class { 'osnailyfacter::apache':
      listen_ports => hiera_array('apache_ports', ['0.0.0.0:80', '0.0.0.0:8888', '0.0.0.0:5000', '0.0.0.0:35357', '0.0.0.0:8777','0.0.0.0:8042']),
  }

  class { '::aodh::wsgi::apache':
    ssl       => $ssl,
    priority  => '15',
    port      => $aodh_api_bind_port,
    bind_host => $aodh_api_bind_host,
  }

  $haproxy_stats_url = "http://${management_vip}:10000/;csv"
  $aodh_protocol     = get_ssl_property($ssl_hash, {}, 'aodh', 'internal', 'protocol', 'http')
  $aodh_address      = get_ssl_property($ssl_hash, {}, 'aodh', 'internal', 'hostname', [$service_endpoint, $management_vip])
  $aodh_url          = "${aodh_protocol}://${aodh_address}:${aodh_api_bind_port}"

  $lb_defaults = { 'provider' => 'haproxy', 'url' => $haproxy_stats_url }

  if $external_lb {
    $lb_backend_provider = 'http'
    $lb_url              = $aodh_url
  }

  $lb_hash = {
    aodh       => {
      name     => 'aodh',
      provider => $lb_backend_provider,
      url      => $lb_url
    }
  }

  ::osnailyfacter::wait_for_backend {'aodh':
    lb_hash     => $lb_hash,
    lb_defaults => $lb_defaults
  }

  class { '::aodh::evaluator': }
  class { '::aodh::notifier': }
  class { '::aodh::listener': }
  class { '::aodh::client': }

  if $ha_mode {
    include ::cluster::aodh_evaluator

    Package[$::aodh::params::common_package_name] -> Class['::cluster::aodh_evaluator']
    Package[$::aodh::params::evaluator_package_name] -> Class['::cluster::aodh_evaluator']
  }

  Service<| title == 'httpd' |> -> ::Osnailyfacter::Wait_for_backend['aodh']
}
