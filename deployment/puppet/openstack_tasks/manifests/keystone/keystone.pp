class openstack_tasks::keystone::keystone {

  notice('MODULAR: keystone/keystone.pp')

  # Override confguration options
  $override_configuration = hiera_hash('configuration', {})
  override_resources { 'keystone_config':
    data => $override_configuration['keystone_config']
  } ~> Service['httpd']

  $network_scheme = hiera_hash('network_scheme', {})
  $network_metadata = hiera_hash('network_metadata', {})
  prepare_network_config($network_scheme)

  $keystone_hash         = hiera_hash('keystone', {})
  $verbose               = pick($keystone_hash['verbose'], hiera('verbose', true))
  $debug                 = pick($keystone_hash['debug'], hiera('debug', false))
  $use_neutron           = hiera('use_neutron', false)
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
  $workers_max           = hiera('workers_max', 16)
  $service_workers       = pick($keystone_hash['workers'],
                                min(max($::processorcount, 2), $workers_max))
  $default_log_levels    = hiera_hash('default_log_levels')
  $primary_controller    = hiera('primary_controller')
  $kombu_compression     = hiera('kombu_compression', '')

  $default_role = '_member_'

  $db_type     = 'mysql'
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

  $admin_token    = $keystone_hash['admin_token']
  $admin_tenant   = $access_hash['tenant']
  $admin_email    = $access_hash['email']
  $admin_user     = $access_hash['user']
  $admin_password = $access_hash['password']
  $region         = hiera('region', 'RegionOne')

  $public_ssl_hash         = hiera_hash('public_ssl')
  $ssl_hash                = hiera_hash('use_ssl', {})

  $public_cert             = get_ssl_property($ssl_hash, $public_ssl_hash, 'keystone', 'public', 'path', [''])

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

  $memcache_server_port   = hiera('memcache_server_port', '11211')
  $memcache_pool_maxsize  = '100'
  $memcache_servers       = suffix(hiera('memcached_addresses'), inline_template(':<%= @memcache_server_port %>'))
  $cache_backend          = 'dogpile.cache.pylibmc'
  $token_caching          = false
  $token_driver           = 'keystone.token.persistence.backends.memcache_pool.Token'
  $token_provider = hiera('token_provider')
  $revoke_driver = 'keystone.contrib.revoke.backends.sql.Revoke'

  $public_url   = "${public_protocol}://${public_address}:${public_port}"
  $admin_url    = "${admin_protocol}://${admin_address}:${admin_port}"
  $internal_url = "${internal_protocol}://${internal_address}:${internal_port}"

  $auth_suffix  = pick($keystone_hash['auth_suffix'], '/')
  $auth_url     = "${internal_url}${auth_suffix}"

  $enabled = true
  $ssl = false

  $vhost_limit_request_field_size = 'LimitRequestFieldSize 81900'

  $rabbit_password     = $rabbit_hash['password']
  $rabbit_user         = $rabbit_hash['user']
  $rabbit_hosts        = split(hiera('amqp_hosts',''), ',')

  $max_pool_size = hiera('max_pool_size')
  $max_overflow  = hiera('max_overflow')
  $max_retries   = '-1'
  $database_idle_timeout  = '3600'

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

  ####### WSGI ###########

  # Listen directives with host required for ip_based vhosts
  class { '::osnailyfacter::apache':
    listen_ports => hiera_array('apache_ports', ['0.0.0.0:80', '0.0.0.0:8888', '0.0.0.0:5000', '0.0.0.0:35357']),
  }

  class { '::keystone::wsgi::apache':
    priority              => '05',
    threads               => 3,
    workers               => min($::processorcount, 6),
    ssl                   => $ssl,
    vhost_custom_fragment => $vhost_limit_request_field_size,
    access_log_format     => '%{X-Forwarded-For}i %l %u %t \"%r\" %>s %b %D \"%{Referer}i\" \"%{User-Agent}i\"',

    # ports and host should be set for ip_based vhost
    public_port           => $public_port,
    admin_port            => $admin_port,
    bind_host             => $local_address_for_bind,

    wsgi_script_ensure    => $::osfamily ? {
      'RedHat' => 'link',
      default  => 'file',
    },
    wsgi_script_source    => $::osfamily ? {
    # TODO: (adidenko) use file from package for Debian, when
    # https://bugs.launchpad.net/fuel/+bug/1476688 is fixed.
    # 'Debian'      => '/usr/share/keystone/wsgi.py',
      'RedHat' => '/usr/share/keystone/keystone.wsgi',
      default  => undef,
    },
  }

  include ::tweaks::apache_wrappers

  ###############################################################################

  if $primary_controller {

    keystone_role { "$default_role":
      ensure => present,
    }

    class { '::keystone::roles::admin':
      admin        => $admin_user,
      password     => $admin_password,
      email        => $admin_email,
      admin_tenant => $admin_tenant,
    }

    Exec <| title == 'keystone-manage db_sync' |> ->
    Keystone_role["$default_role"] ->
    Class['::keystone::roles::admin'] ->
    Osnailyfacter::Credentials_file <||>

    Class['::osnailyfacter::wait_for_keystone_backends'] -> Keystone_role["$default_role"]
    Class['::osnailyfacter::wait_for_keystone_backends'] -> Class['::keystone::roles::admin']

  }

  osnailyfacter::credentials_file { '/root/openrc':
    admin_user          => $admin_user,
    admin_password      => $admin_password,
    admin_tenant        => $admin_tenant,
    region_name         => $region,
    auth_url            => $auth_url,
    murano_repo_url     => $murano_repo_url,
    murano_glare_plugin => $murano_glare_plugin,
  }

  osnailyfacter::credentials_file { "${operator_user_homedir}/openrc":
    admin_user          => $admin_user,
    admin_password      => $admin_password,
    admin_tenant        => $admin_tenant,
    region_name         => $region,
    auth_url            => $auth_url,
    murano_repo_url     => $murano_repo_url,
    murano_glare_plugin => $murano_glare_plugin,
    owner               => $operator_user_name,
    group               => $operator_user_name,
  }

  osnailyfacter::credentials_file { "${service_user_homedir}/openrc":
    admin_user          => $admin_user,
    admin_password      => $admin_password,
    admin_tenant        => $admin_tenant,
    region_name         => $region,
    auth_url            => $auth_url,
    murano_repo_url     => $murano_repo_url,
    murano_glare_plugin => $murano_glare_plugin,
    owner               => $service_user_name,
    group               => $service_user_name,
  }

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
      require => Class['::keystone'],
      notify  => Service[httpd],
    }
  }

  ensure_packages('python-pylibmc')

  if $enabled {
    class { '::keystone':
      enable_bootstrap             => true,
      verbose                      => $verbose,
      debug                        => $debug,
      catalog_type                 => 'sql',
      admin_token                  => $admin_token,
      enabled                      => false,
      database_connection          => $db_connection,
      database_max_retries         => $max_retries,
      database_max_pool_size       => $max_pool_size,
      database_max_overflow        => $max_overflow,
      public_bind_host             => $local_address_for_bind,
      admin_bind_host              => $local_address_for_bind,
      admin_workers                => $service_workers,
      public_workers               => $service_workers,
      use_syslog                   => $use_syslog,
      use_stderr                   => $use_stderr,
      database_idle_timeout        => $database_idle_timeout,
      sync_db                      => $primary_controller,
      rabbit_password              => $rabbit_password,
      rabbit_userid                => $rabbit_user,
      rabbit_hosts                 => $rabbit_hosts,
      memcache_servers             => $memcache_servers,
      token_driver                 => $token_driver,
      token_provider               => $token_provider,
      notification_driver          => $ceilometer_hash['notification_driver'],
      token_caching                => $token_caching,
      cache_backend                => $cache_backend,
      revoke_driver                => $revoke_driver,
      admin_endpoint               => $admin_url,
      memcache_dead_retry          => '60',
      memcache_socket_timeout      => '1',
      memcache_pool_maxsize        =>'1000',
      memcache_pool_unused_timeout => '60',
      cache_memcache_servers       => $memcache_servers,
      policy_driver                => 'keystone.policy.backends.sql.Policy',
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

    # FIXME(mattymo): After LP#1528258 is closed, this can be removed. It will
    # become a default option.
    keystone_config {
      'DEFAULT/secure_proxy_ssl_header': value => 'HTTP_X_FORWARDED_PROTO';
    }

    keystone_config {
      'identity/driver':                                 value =>'keystone.identity.backends.sql.Identity';
      'ec2/driver':                                      value =>'keystone.contrib.ec2.backends.sql.Ec2';
      'filter:debug/paste.filter_factory':               value =>'keystone.common.wsgi:Debug.factory';
      'filter:token_auth/paste.filter_factory':          value =>'keystone.middleware:TokenAuthMiddleware.factory';
      'filter:admin_token_auth/paste.filter_factory':    value =>'keystone.middleware:AdminTokenAuthMiddleware.factory';
      'filter:xml_body/paste.filter_factory':            value =>'keystone.middleware:XmlBodyMiddleware.factory';
      'filter:json_body/paste.filter_factory':           value =>'keystone.middleware:JsonBodyMiddleware.factory';
      'filter:user_crud_extension/paste.filter_factory': value =>'keystone.contrib.user_crud:CrudExtension.factory';
      'filter:crud_extension/paste.filter_factory':      value =>'keystone.contrib.admin_crud:CrudExtension.factory';
      'filter:ec2_extension/paste.filter_factory':       value =>'keystone.contrib.ec2:Ec2Extension.factory';
      'filter:s3_extension/paste.filter_factory':        value =>'keystone.contrib.s3:S3Extension.factory';
      'filter:url_normalize/paste.filter_factory':       value =>'keystone.middleware:NormalizingFilter.factory';
      'filter:stats_monitoring/paste.filter_factory':    value =>'keystone.contrib.stats:StatsMiddleware.factory';
      'filter:stats_reporting/paste.filter_factory':     value =>'keystone.contrib.stats:StatsExtension.factory';
      'app:public_service/paste.app_factory':            value =>'keystone.service:public_app_factory';
      'app:admin_service/paste.app_factory':             value =>'keystone.service:admin_app_factory';
      'pipeline:public_api/pipeline':                    value =>'stats_monitoring url_normalize token_auth admin_token_auth xml_body json_body debug ec2_extension user_crud_extension public_service';
      'pipeline:admin_api/pipeline':                     value =>'stats_monitoring url_normalize token_auth admin_token_auth xml_body json_body debug stats_reporting ec2_extension s3_extension crud_extension admin_service';
      'app:public_version_service/paste.app_factory':    value =>'keystone.service:public_version_app_factory';
      'app:admin_version_service/paste.app_factory':     value =>'keystone.service:admin_version_app_factory';
      'pipeline:public_version_api/pipeline':            value =>'stats_monitoring url_normalize xml_body public_version_service';
      'pipeline:admin_version_api/pipeline':             value =>'stats_monitoring url_normalize xml_body admin_version_service';
      'composite:main/use':                              value =>'egg:Paste#urlmap';
      'composite:main//v2.0':                            value =>'public_api';
      'composite:main//':                                value =>'public_version_api';
      'composite:admin/use':                             value =>'egg:Paste#urlmap';
      'composite:admin//v2.0':                           value =>'admin_api';
      'composite:admin//':                               value =>'admin_version_api';
    }

    # TODO (iberezovskiy): remove this workaround in N when keystone module
    # will be switched to puppet-oslo usage for rabbit configuration
    if $kombu_compression in ['gzip','bz2'] {
      if !defined(Oslo::Messaging_rabbit['keystone_config']) and !defined(Keystone_config['oslo_messaging_rabbit/kombu_compression']) {
        keystone_config { 'oslo_messaging_rabbit/kombu_compression': value => $kombu_compression; }
      } else {
        Keystone_config<| title == 'oslo_messaging_rabbit/kombu_compression' |> { value => $kombu_compression }
      }
    }

    class { '::keystone::endpoint':
      public_url   => $public_url,
      admin_url    => $admin_url,
      internal_url => $internal_url,
      region       => $region,
    }

    Exec <| title == 'keystone-manage db_sync' |> -> Class['::keystone::endpoint']
  }

}
