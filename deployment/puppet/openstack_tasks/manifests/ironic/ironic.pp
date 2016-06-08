class openstack_tasks::ironic::ironic {

  notice('MODULAR: ironic/ironic.pp')

  $ironic_hash                = hiera_hash('ironic', {})
  $public_vip                 = hiera('public_vip')
  $management_vip             = hiera('management_vip')
  $service_endpoint           = hiera('service_endpoint')

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
  $rabbit_hash                = hiera_hash('rabbit', {})
  $amqp_hosts                 = hiera('amqp_hosts')
  $amqp_port                  = hiera('amqp_port', '5673')
  $rabbit_hosts               = split($amqp_hosts, ',')
  $neutron_config             = hiera_hash('quantum_settings')
  $primary_controller         = hiera('primary_controller')
  $amqp_durable_queues        = pick($ironic_hash['amqp_durable_queues'], false)
  $kombu_compression          = hiera('kombu_compression', '')

  $db_type                    = 'mysql+pymysql'
  $db_host                    = pick($ironic_hash['db_host'], $database_vip)
  $db_user                    = pick($ironic_hash['db_user'], 'ironic')
  $db_name                    = pick($ironic_hash['db_name'], 'ironic')
  $db_password                = pick($ironic_hash['db_password'], 'ironic')
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

  $ironic_tenant              = pick($ironic_hash['tenant'],'services')
  $ironic_user                = pick($ironic_hash['auth_name'],'ironic')
  $ironic_user_password       = pick($ironic_hash['user_password'],'ironic')
  $ssl_hash                   = hiera_hash('use_ssl', {})
  $public_ssl_hash            = hiera_hash('public_ssl', {})
  $internal_auth_protocol     = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
  $internal_auth_address      = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [$service_endpoint, $management_vip])
  $internal_auth_url          = "${internal_auth_protocol}://${internal_auth_address}:5000"
  $admin_identity_protocol    = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
  $admin_identity_address     = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [$service_endpoint, $management_vip])
  $admin_identity_uri         = "${admin_identity_protocol}://${admin_identity_address}:35357"
  $public_protocol            = get_ssl_property($ssl_hash, $public_ssl_hash, 'ironic', 'public', 'protocol', 'http')
  $public_address             = get_ssl_property($ssl_hash, $public_ssl_hash, 'ironic', 'public', 'hostname', $public_vip)

  prepare_network_config(hiera_hash('network_scheme', {}))

  $baremetal_vip = $network_metadata['vips']['baremetal']['ipaddr']

  class { '::ironic':
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
    database_connection  => $db_connection,
    database_max_retries => '-1',
    glance_api_servers   => $glance_api_servers,
    sync_db              => $primary_controller,
  }

  class { '::ironic::client': }

  class { '::ironic::api':
    host_ip           => get_network_role_property('ironic/api', 'ipaddr'),
    auth_uri          => $internal_auth_url,
    identity_uri      => $admin_identity_uri,
    admin_tenant_name => $ironic_tenant,
    admin_user        => $ironic_user,
    admin_password    => $ironic_user_password,
    neutron_url       => "http://${neutron_endpoint}:9696",
    public_endpoint   => "${public_protocol}://${public_address}:6385",
  }

  # TODO (iberezovskiy): remove this workaround in N when ironic module
  # will be switched to puppet-oslo usage for rabbit configuration
  if $kombu_compression in ['gzip','bz2'] {
    if !defined(Oslo::Messaging_rabbit['ironic_config']) and !defined(Ironic_config['oslo_messaging_rabbit/kombu_compression']) {
      ironic_config { 'oslo_messaging_rabbit/kombu_compression': value => $kombu_compression; }
    } else {
      Ironic_config<| title == 'oslo_messaging_rabbit/kombu_compression' |> { value => $kombu_compression }
    }
  }
}
