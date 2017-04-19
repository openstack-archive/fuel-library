class openstack_tasks::heat::heat {

  notice('MODULAR: heat/heat.pp')

  prepare_network_config(hiera_hash('network_scheme', {}))
  $heat_hash                = hiera_hash('heat', {})
  $sahara_hash              = hiera_hash('sahara', {})
  $rabbit_hash              = hiera_hash('rabbit', {})
  $ceilometer_hash          = hiera_hash('ceilometer', {})
  $max_retries              = hiera('max_retries')
  $max_pool_size            = hiera('max_pool_size')
  $max_overflow             = hiera('max_overflow')
  $idle_timeout             = hiera('idle_timeout')
  $keystone_host            = hiera('service_endpoint')
  $public_ssl_hash          = hiera_hash('public_ssl')
  $ssl_hash                 = hiera_hash('use_ssl', {})
  $public_vip               = hiera('public_vip')
  $management_vip           = hiera('management_vip')
  $primary_controller       = hiera('primary_controller')
  $kombu_compression        = hiera('kombu_compression', $::os_service_default)

  $heat_domain_name          = pick($heat_hash['domain_name'], 'heat')
  $heat_domain_admin         = pick($heat_hash['domain_admin'], 'heat_admin')
  $heat_domain_password      = $heat_hash['user_password']

  $public_auth_protocol     = get_ssl_property($ssl_hash, $public_ssl_hash, 'keystone', 'public', 'protocol', 'http')
  $public_auth_address      = get_ssl_property($ssl_hash, $public_ssl_hash, 'keystone', 'public', 'hostname', [$public_vip])
  $internal_auth_protocol   = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
  $internal_auth_address    = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [$keystone_host, $management_vip])
  $admin_auth_protocol      = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
  $admin_auth_address       = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [$keystone_host, $management_vip])

  $heat_protocol            = get_ssl_property($ssl_hash, $public_ssl_hash, 'heat', 'public', 'protocol', 'http')
  $heat_endpoint            = get_ssl_property($ssl_hash, $public_ssl_hash, 'heat', 'public', 'hostname', [hiera('heat_endpoint', ''), $public_vip])
  $public_ssl               = get_ssl_property($ssl_hash, {}, 'heat', 'public', 'usage', false)

  $auth_uri                 = "${public_auth_protocol}://${public_auth_address}:5000/v2.0/"
  $auth_url                 = "${admin_auth_protocol}://${admin_auth_address}:35357/"
  $keystone_ec2_uri         = "${internal_auth_protocol}://${internal_auth_address}:5000/v2.0"

  $api_bind_port            = '8004'
  $api_cfn_bind_port        = '8000'
  $api_cloudwatch_bind_port = '8003'
  $metadata_server_url      = "${heat_protocol}://${heat_endpoint}:${api_cfn_bind_port}"
  $waitcondition_server_url = "${metadata_server_url}/v1/waitcondition"
  $watch_server_url         = "${heat_protocol}://${heat_endpoint}:${api_cloudwatch_bind_port}"

  $debug                    = pick($heat_hash['debug'], hiera('debug', false))
  $use_stderr               = hiera('use_stderr', false)
  $use_syslog               = hiera('use_syslog', true)
  $syslog_log_facility      = hiera('syslog_log_facility_heat')
  $deployment_mode          = hiera('deployment_mode')
  $bind_host                = get_network_role_property('heat/api', 'ipaddr')
  $memcached_servers        = hiera('memcached_servers')
  $local_memcached_server = hiera('local_memcached_server')
  $keystone_user            = pick($heat_hash['user'], 'heat')
  $keystone_tenant          = pick($heat_hash['tenant'], 'services')
  $region                   = hiera('region', 'RegionOne')
  $external_lb              = hiera('external_lb', false)

  $rabbit_heartbeat_timeout_threshold = pick($heat_hash['rabbit_heartbeat_timeout_threshold'], $rabbit_hash['heartbeat_timeout_threshold'], 60)
  $rabbit_heartbeat_rate              = pick($heat_hash['rabbit_heartbeat_rate'], $rabbit_hash['rabbit_heartbeat_rate'], 2)

  $storage_hash = hiera_hash('storage', {})

  $db_type     = pick($heat_hash['db_type'], 'mysql+pymysql')
  $db_host     = pick($heat_hash['db_host'], hiera('database_vip'))
  $db_user     = pick($heat_hash['db_user'], 'heat')
  $db_password = $heat_hash['db_password']
  $db_name     = hiera('heat_db_name', 'heat')
  # LP#1526938 - python-mysqldb supports this, python-pymysql does not
  if $::os_package_type == 'debian' {
    $extra_params = { 'charset' => 'utf8', 'read_timeout' => 60 }
  } else {
    $extra_params = { 'charset' => 'utf8' }
  }
  $db_connection = os_database_connection({
    'dialect'  => $db_type,
    'host'     => $db_host,
    'database' => $db_name,
    'username' => $db_user,
    'password' => $db_password,
    'extra'    => $extra_params
  })

  $transport_url = hiera('transport_url','rabbit://guest:password@127.0.0.1:5672/')

  ####### Disable upstart startup on install #######
  if $::operatingsystem == 'Ubuntu' {
    tweaks::ubuntu_service_override { 'heat-api-cloudwatch':
      package_name => 'heat-api-cloudwatch',
    }
    tweaks::ubuntu_service_override { 'heat-api-cfn':
      package_name => 'heat-api-cfn',
    }
    tweaks::ubuntu_service_override { 'heat-api':
      package_name => 'heat-api',
    }
    tweaks::ubuntu_service_override { 'heat-engine':
      package_name => 'heat-engine',
    }

    Tweaks::Ubuntu_service_override['heat-api']            -> Service['heat-api']
    Tweaks::Ubuntu_service_override['heat-api-cfn']        -> Service['heat-api-cfn']
    Tweaks::Ubuntu_service_override['heat-api-cloudwatch'] -> Service['heat-api-cloudwatch']
    Tweaks::Ubuntu_service_override['heat-engine']         -> Service['heat-engine']
  }

  # Turn on Caching for Heat validation process
  heat_config {
    'cache/enabled':          value => true;
    'cache/backend':          value => 'oslo_cache.memcache_pool';
    'cache/memcache_servers': value => $local_memcached_server;
  }

  # TODO(aschultz): ubuntu does not have a heat docker package
  if !$::os_package_type or $::os_package_type != 'ubuntu' {
    if $::osfamily == 'RedHat' {
      $docker_resource_package_name = 'openstack-heat-docker'
    } elsif $::osfamily == 'Debian' {
      $docker_resource_package_name = 'heat-docker'
    }

    class { '::openstack_tasks::heat::docker_resource' :
      package_name => $docker_resource_package_name,
    }
  }

  $haproxy_stats_url = "http://${service_endpoint}:10000/;csv"

  class { '::osnailyfacter::wait_for_keystone_backends':}

  class { '::heat::keystone::domain' :
    domain_name        => $heat_domain_name,
    domain_admin       => $heat_domain_admin,
    domain_password    => $heat_domain_password,
    domain_admin_email => 'heat_admin@localhost',
    manage_domain      => true,
  }

  Class['::heat'] ->
    Class['::osnailyfacter::wait_for_keystone_backends'] ->
      Class['::heat::keystone::domain'] ~>
        Service<| title == 'heat-engine' |>

  ######################

  exec { 'wait_for_heat_config' :
    command     => 'sync && sleep 3',
    provider    => 'shell',
    refreshonly => true,
  }

  Heat_config <||> ~>
    Exec['wait_for_heat_config'] ->
      Service <| tag == 'heat-service' |>

  # No empty passwords allowed
  validate_string($amqp_password)

  Package<| title == 'heat-api-cfn' or title == 'heat-api-cloudwatch' |> ->
  Heat_config <|
    title == 'DEFAULT/instance_connection_https_validate_certificates' or
    title == 'DEFAULT/instance_connection_is_secure'
  |> ->
  Service<| title == 'heat-api-cfn' or title == 'heat-api-cloudwatch' |>

  # Syslog configuration
  if $use_syslog {
    heat_config {
      'DEFAULT/use_syslog_rfc_format': value => true;
    }
  }

  class { '::heat::keystone::authtoken':
    username          => $keystone_user,
    password          => $heat_hash['user_password'],
    project_name      => $keystone_tenant,
    auth_uri          => $auth_uri,
    auth_url          => $auth_url,
    memcached_servers => $local_memcached_server,
  }

  # Common configuration, logging and RPC
  class { '::heat':
    keystone_ec2_uri                   => $keystone_ec2_uri,
    region_name                        => $region,

    database_connection                => $db_connection,
    database_idle_timeout              => $idle_timeout,
    sync_db                            => $primary_controller,

    default_transport_url              => $transport_url,
    rpc_response_timeout               => '600',
    rabbit_heartbeat_timeout_threshold => $rabbit_heartbeat_timeout_threshold,
    rabbit_heartbeat_rate              => $rabbit_heartbeat_rate,

    log_dir                            => '/var/log/heat',
    debug                              => $debug,
    use_syslog                         => $use_syslog,
    use_stderr                         => $use_stderr,
    log_facility                       => $syslog_log_facility,

    max_template_size                  => '5440000',
    max_json_body_size                 => '10880000',
    notification_driver                => $ceilometer_hash['notification_driver'],
    heat_clients_url                   => "${heat_protocol}://${public_vip}:${api_bind_port}/v1/%(tenant_id)s",

    database_max_pool_size             => $max_pool_size,
    database_max_overflow              => $max_overflow,
    database_max_retries               => $max_retries,

    kombu_compression                  => $kombu_compression,
    enable_proxy_headers_parsing       => true,
  }

  # Engine
  class { '::heat::engine' :
    auth_encryption_key                             => $heat_hash['auth_encryption_key'],
    heat_metadata_server_url                        => $metadata_server_url,
    heat_waitcondition_server_url                   => $waitcondition_server_url,
    heat_watch_server_url                           => $watch_server_url,
    # TODO(iberezovskiy) Added in 99ad7e2d, but not inline with upstream,
    # please coment which to use
    # https://github.com/openstack/puppet-heat/blob/master/manifests/engine.pp#L105
    trusts_delegated_roles                          => [],
    max_resources_per_stack                         => '20000',
    instance_connection_https_validate_certificates => '1',
    instance_connection_is_secure                   => '0',
  }

  # [mkarpin] TODO: rework this when 
  # https://review.openstack.org/#/c/457869/ is merged
  if $sahara_hash['enabled'] and !$storage_hash['objects_ceph'] {
    if !defined(Heat_config['DEFAULT/reauthentication_auth_method']) {
      heat_config { 'DEFAULT/reauthentication_auth_method':
        value => 'trusts'
      }
    } else {
      Heat_config <| title == 'DEFAULT/reauthentication_auth_method' |> {
        value => 'trusts'
      }
    }
  }

  # TODO(dmburmistrov): completely remove pacemaker for heat-engine after release "N"
  if hiera('heat_ha_engine', true) and hiera('heat_pcs_engine', false) {
    if $deployment_mode in ['ha', 'ha_compact'] {
      warning('Pacemaker for heat-engine will be dropped in the next release.')
      include ::cluster::heat_engine
    }
  }

  # Install the heat APIs
  class { '::heat::api':
    bind_host => $bind_host,
    bind_port => $api_bind_port,
  }
  class { '::heat::api_cfn' :
    bind_host => $bind_host,
    bind_port => $api_cfn_bind_port,
  }
  class { '::heat::api_cloudwatch' :
    bind_host => $bind_host,
    bind_port => $api_cloudwatch_bind_port,

  }
  # Client
  class { '::heat::client' :  }

  # tweak 'heat-dbsync' exec
  # TODO(mmalchuk) remove this after LP#1628580 merged
  Exec<| title == 'heat-dbsync' |> {
    tries     => '10',
    try_sleep => '5',
  }

}
