class openstack_tasks::keystone::keystone {

  notice('MODULAR: keystone/keystone.pp')

  $network_scheme   = hiera_hash('network_scheme', {})
  $network_metadata = hiera_hash('network_metadata', {})
  prepare_network_config($network_scheme)

  $keystone_hash         = hiera_hash('keystone', {})
  $debug                 = pick($keystone_hash['debug'], hiera('debug', false))
  $use_syslog            = hiera('use_syslog', true)
  $use_stderr            = hiera('use_stderr', false)
  $access_hash           = hiera_hash('access', {})
  $management_vip        = hiera('management_vip')
  $database_vip          = hiera('database_vip')
  $public_vip            = hiera('public_vip')
  $service_endpoint      = hiera('service_endpoint')
  $glance_hash           = hiera_hash('glance', {})
  $nova_hash             = hiera_hash('nova', {})
  $cinder_hash           = hiera_hash('cinder', {})
  $ceilometer_hash       = hiera_hash('ceilometer', {})
  $syslog_log_facility   = hiera('syslog_log_facility_keystone')
  $rabbit_hash           = hiera_hash('rabbit', {})
  $neutron_user_password = hiera('neutron_user_password', false)
  $workers_max           = hiera('workers_max', $::os_workers)
  $service_workers       = pick($keystone_hash['workers'],
                                min(max($::processorcount, 2), $workers_max))
  $default_log_levels    = hiera_hash('default_log_levels')
  $primary_keystone      = has_primary_role(intersection(hiera('keystone_roles'), hiera('roles')))
  $kombu_compression     = hiera('kombu_compression', $::os_service_default)

  $default_role = '_member_'

  $user_admin_role   = hiera('user_admin_role')
  $user_admin_domain = hiera('user_admin_domain')

  $db_type     = pick($keystone_hash['db_type'], 'mysql+pymysql')
  $db_host     = pick($keystone_hash['db_host'], $database_vip)
  $db_password = $keystone_hash['db_password']
  $db_name     = pick($keystone_hash['db_name'], 'keystone')
  $db_user     = pick($keystone_hash['db_user'], 'keystone')
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

  $admin_token    = $keystone_hash['admin_token']
  $admin_tenant   = $access_hash['tenant']
  $admin_email    = $access_hash['email']
  $admin_user     = $access_hash['user']
  $admin_password = $access_hash['password']
  $region         = hiera('region', 'RegionOne')

  $public_ssl_hash = hiera_hash('public_ssl')
  $ssl_hash        = hiera_hash('use_ssl', {})

  $public_cert = get_ssl_property($ssl_hash, $public_ssl_hash, 'keystone', 'public', 'path', [''])

  $public_protocol = get_ssl_property($ssl_hash, $public_ssl_hash, 'keystone', 'public', 'protocol', 'http')
  $public_address  = get_ssl_property($ssl_hash, $public_ssl_hash, 'keystone', 'public', 'hostname', [$public_vip])
  $public_port     = '5000'

  $internal_protocol = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
  $internal_address  = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [$service_endpoint, $management_vip])
  $internal_port     = '5000'

  $admin_protocol = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
  $admin_address  = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [$service_endpoint, $management_vip])
  $admin_port     = '35357'

  $local_address_for_bind = get_network_role_property('keystone/api', 'ipaddr')

  $memcache_pool_maxsize = '100'
  $memcache_servers      = hiera('memcached_servers')
  $cache_backend         = 'oslo_cache.memcache_pool'
  $token_caching         = false
  $token_driver          = 'keystone.token.persistence.backends.memcache_pool.Token'
  $token_provider        = hiera('token_provider')

  $public_url   = "${public_protocol}://${public_address}:${public_port}"
  $admin_url    = "${admin_protocol}://${admin_address}:${admin_port}"
  $internal_url = "${internal_protocol}://${internal_address}:${internal_port}"

  $auth_suffix  = pick($keystone_hash['auth_suffix'], '/')
  $auth_url     = "${internal_url}${auth_suffix}"

  $enabled = true
  $ssl     = false

  $vhost_limit_request_field_size = 'LimitRequestFieldSize 81900'

  $max_pool_size         = hiera('max_pool_size')
  $max_overflow          = hiera('max_overflow')
  $max_retries           = '-1'
  $database_idle_timeout = '3600'

  $murano_settings_hash = hiera_hash('murano_settings', {})
  if has_key($murano_settings_hash, 'murano_repo_url') {
    $murano_repo_url = $murano_settings_hash['murano_repo_url']
  } else {
    $murano_repo_url = 'http://storage.apps.openstack.org'
  }

  $murano_hash    = hiera_hash('murano', {})
  $murano_plugins = pick($murano_hash['plugins'], {})
  if has_key($murano_plugins, 'glance_artifacts_plugin') {
    $murano_glare_plugin = $murano_plugins['glance_artifacts_plugin']['enabled']
  } else {
    $murano_glare_plugin = false
  }

  $external_lb = hiera('external_lb', false)

  $operator_user_hash    = hiera_hash('operator_user', {})
  $service_user_hash     = hiera_hash('service_user', {})
  $operator_user_name    = pick($operator_user_hash['name'], 'fueladmin')
  $operator_user_homedir = pick($operator_user_hash['homedir'], '/home/fueladmin')
  $service_user_name     = pick($service_user_hash['name'], 'fuel')
  $service_user_homedir  = pick($service_user_hash['homedir'], '/var/lib/fuel')

  $rabbit_heartbeat_timeout_threshold = pick($keystone_hash['rabbit_heartbeat_timeout_threshold'], $rabbit_hash['heartbeat_timeout_threshold'], 60)
  $rabbit_heartbeat_rate              = pick($keystone_hash['rabbit_heartbeat_rate'], $rabbit_hash['rabbit_heartbeat_rate'], 2)

  ####### WSGI ###########

  # Listen directives with host required for ip_based vhosts
  class { '::osnailyfacter::apache':
    listen_ports => hiera_array('apache_ports', ['0.0.0.0:80', '0.0.0.0:8888', '0.0.0.0:5000', '0.0.0.0:35357']),
  }

  class { '::keystone::wsgi::apache':
    priority              => '05',
    threads               => 1,
    workers               => min($::processorcount, 6),
    ssl                   => $ssl,
    vhost_custom_fragment => $vhost_limit_request_field_size,
    access_log_format     => '%{X-Forwarded-For}i %l %u %{%d/%b/%Y:%T}t.%{msec_frac}t \"%r\" %>s %b %D \"%{Referer}i\" \"%{User-Agent}i\"',

    # ports and host should be set for ip_based vhost
    public_port           => $public_port,
    admin_port            => $admin_port,
    bind_host             => $local_address_for_bind,

    wsgi_script_ensure    => 'link',
  }

  include ::tweaks::apache_wrappers

  ###############################################################################

  if $primary_keystone {

    keystone_role { "$default_role":
      ensure => present,
    }

    class { '::keystone::roles::admin':
      admin        => $admin_user,
      password     => $admin_password,
      email        => $admin_email,
      admin_tenant => $admin_tenant,
    }

    #assign 'admin' role for 'admin' user in 'Default' domain
    keystone_user_role { "${admin_user}@::${user_admin_domain}":
      ensure         => present,
      roles          => any2array($user_admin_role),
    }

    Exec <| title == 'keystone-manage db_sync' |> ->
    Keystone_role["$default_role"] ->
    Class['::keystone::roles::admin'] ->
    Keystone_user_role["${admin_user}@::${user_admin_domain}"] ->
    Osnailyfacter::Credentials_file <||>

    Class['::osnailyfacter::wait_for_keystone_backends'] -> Keystone_role["$default_role"]
    Class['::osnailyfacter::wait_for_keystone_backends'] -> Class['::keystone::roles::admin']

    # tweak 'keystone-exec' exec
    # TODO(mmalchuk) remove this after LP#1628580 merged
    Exec<| tag == 'keystone-exec' |> {
      tries => '10',
      try_sleep => '5',
    }
  }

  group { 'operator_group' :
    name   => $operator_user_name,
    ensure => present,
  }

  user { 'operator_user':
    name       => $operator_user_name,
    gid        => $operator_user_name,
    ensure     => present,
    managehome => true,
    home       => $operator_user_homedir,
  }

  group { 'service_group' :
    name   => $service_user_name,
    ensure => present,
  }

  user { 'service_user':
    name       => $service_user_name,
    gid        => $service_user_name,
    ensure     => present,
    managehome => true,
    home       => $service_user_homedir,
  }

  $users = {
    "${operator_user_name}" => 'operator_user',
    "${service_user_name}"  => 'service_user',
  }

  $cred_users = {
    '/root/openrc'                    => 'root',
    "${operator_user_homedir}/openrc" => $operator_user_name,
    "${service_user_homedir}/openrc"  => $service_user_name,
  }

  $cred_params = {
    'admin_user'          => $admin_user,
    'admin_password'      => $admin_password,
    'admin_tenant'        => $admin_tenant,
    'region_name'         => $region,
    'auth_url'            => $auth_url,
    'murano_repo_url'     => $murano_repo_url,
    'murano_glare_plugin' => $murano_glare_plugin
  }

  create_resources('osnailyfacter::credentials_file', get_cred_files_hash($cred_users, $cred_params, $users))

  # Get paste.ini source
  include ::keystone::params
  $keystone_paste_ini = $::keystone::params::paste_config ? {
    undef   => '/etc/keystone/keystone-paste.ini',
    default => $::keystone::params::paste_config,
  }

  # Make sure admin token auth middleware is in place
  exec { 'add_admin_token_auth_middleware':
    path    => ['/bin', '/usr/bin'],
    command => "sed -i 's/\\( token_auth \\)/\\1admin_token_auth /' ${keystone_paste_ini}",
    unless  => "fgrep -q ' admin_token_auth' ${keystone_paste_ini}",
    require => Package['keystone'],
  }

  Exec['add_admin_token_auth_middleware'] ->
  Exec <| title == 'keystone-manage db_sync' |> ->
  Osnailyfacter::Credentials_file <||>

  $haproxy_stats_url = "http://${service_endpoint}:10000/;csv"

  class { '::osnailyfacter::wait_for_keystone_backends':}

  Service['keystone'] -> Class['::osnailyfacter::wait_for_keystone_backends']
  Service<| title == 'httpd' |> -> Class['::osnailyfacter::wait_for_keystone_backends']
  Class['::osnailyfacter::wait_for_keystone_backends'] -> Class['::keystone::endpoint']

  ####### Disable upstart startup on install #######
  if ($::operatingsystem == 'Ubuntu') {
    tweaks::ubuntu_service_override { 'keystone':
      package_name => 'keystone',
    }
  }

  #### Fernet Token ####
  if $token_provider == 'keystone.token.providers.fernet.Provider' {
    file { '/etc/keystone/fernet-keys':
      source  => '/var/lib/astute/keystone',
      mode    => '0600',
      owner   => 'keystone',
      group   => 'keystone',
      recurse => true,
      require => Anchor['keystone::install::end'],
      notify  => Anchor['keystone::config::end'],
    }
  }

  if $enabled {
    class { '::keystone':
      enable_bootstrap                   => true,
      debug                              => $debug,
      catalog_type                       => 'sql',
      admin_token                        => $admin_token,
      admin_password                     => $admin_password,
      enabled                            => false,
      database_connection                => $db_connection,
      default_transport_url              => $transport_url,
      database_max_retries               => $max_retries,
      database_max_pool_size             => $max_pool_size,
      database_max_overflow              => $max_overflow,
      public_bind_host                   => $local_address_for_bind,
      admin_bind_host                    => $local_address_for_bind,
      admin_workers                      => $service_workers,
      public_workers                     => $service_workers,
      use_syslog                         => $use_syslog,
      use_stderr                         => $use_stderr,
      database_idle_timeout              => $database_idle_timeout,
      sync_db                            => $primary_keystone,
      memcache_servers                   => $memcache_servers,
      token_driver                       => $token_driver,
      token_provider                     => $token_provider,
      # Fernet keys are generated on master
      enable_fernet_setup                => false,
      notification_driver                => $ceilometer_hash['notification_driver'],
      token_caching                      => $token_caching,
      cache_backend                      => $cache_backend,
      admin_endpoint                     => $admin_url,
      memcache_dead_retry                => '60',
      memcache_socket_timeout            => '1',
      memcache_pool_maxsize              => '1000',
      memcache_pool_unused_timeout       => '60',
      cache_memcache_servers             => $memcache_servers,
      policy_driver                      => 'keystone.policy.backends.sql.Policy',
      rabbit_heartbeat_timeout_threshold => $rabbit_heartbeat_timeout_threshold,
      rabbit_heartbeat_rate              => $rabbit_heartbeat_rate,
      kombu_compression                  => $kombu_compression,
      # Set revoke_by_id to false according to LP #1625077
      revoke_by_id                       => false,
    }

    Package<| title == 'keystone'|> ~> Service<| title == 'keystone'|>
    if !defined(Service['keystone']) {
      notify{ "Module ${module_name} cannot notify service keystone on package update": }
    }

    if $use_syslog {
      keystone_config {
        'DEFAULT/use_syslog_rfc_format':  value  => true;
      }
    }

    class { '::keystone::endpoint':
      public_url   => $public_url,
      admin_url    => $admin_url,
      internal_url => $internal_url,
      region       => $region,
      # TODO: Remove version when #1668574 will be fixed in OSTF
      version      => 'unset',
    }

    Exec <| title == 'keystone-manage db_sync' |> -> Class['::keystone::endpoint']
  }

}
