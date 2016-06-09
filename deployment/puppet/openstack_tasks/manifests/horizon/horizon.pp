class openstack_tasks::horizon::horizon {

  notice('MODULAR: horizon/horizon.pp')

  prepare_network_config(hiera_hash('network_scheme', {}))
  $horizon_hash            = hiera_hash('horizon', {})
  $service_endpoint        = hiera('service_endpoint')
  $cache_server_ip         = hiera('memcached_addresses')
  $bind_address            = get_network_role_property('horizon', 'ipaddr')
  $storage_hash            = hiera_hash('storage', {})
  $neutron_advanced_config = hiera_hash('neutron_advanced_configuration', {})
  $public_ssl              = hiera('public_ssl')
  $ssl_no_verify           = $public_ssl['horizon']
  $use_ssl                 = hiera('horizon_use_ssl', false)

  $overview_days_range     = pick($horizon_hash['overview_days_range'], 1)
  $external_lb             = hiera('external_lb', false)
  $repo_setup              = hiera_hash('repo_setup', {})
  $repo_type               = pick_default($repo_setup['repo_type'], '')

  if $horizon_hash['secret_key'] {
    $secret_key = $horizon_hash['secret_key']
  } else {
    $secret_key = 'dummy_secret_key'
  }

  #if $::os_package_type == 'debian' {
  #  $custom_theme_path = hiera('custom_theme_path', 'themes/vendor')
  #} else {
  #  $custom_theme_path = undef
  #}
  # Don't use custom theme until its code lands to MOS 9.0.
  $custom_theme_path = undef

  # TODO(aschultz): the horizon.backends.memcached.HorizonMemcached is only part
  # of the MOS package set. This should be contributed upstream and then we can
  # use this as the default.
  #if !$::os_package_type or $::os_package_type == 'debian' {
  #  $cache_backend = dig44($horizon_hash, ['cache_backend'], 'horizon.backends.memcached.HorizonMemcached')
  #} else {
  #  $cache_backend = dig44($horizon_hash, ['cache_backend'], 'django.core.cache.backends.memcached.MemcachedCache')
  #}
  # Don't use custom backend until its code lands to MOS 9.0.
  $cache_backend = dig44($horizon_hash, ['cache_backend'], 'django.core.cache.backends.memcached.MemcachedCache')

  #Changing from internal addressing to public should resolve any security concerns about exposing 'internal' to public facing login.
  #However, this should eventually be removed altogether from Horizon.
  $public_ssl_hash        = hiera_hash('public_ssl')
  $ssl_hash               = hiera_hash('use_ssl', {})
  $public_vip             = hiera('public_vip')
  $public_auth_protocol   = get_ssl_property($ssl_hash, $public_ssl_hash, 'keystone', 'public', 'protocol', 'http')
  $public_auth_address    = get_ssl_property($ssl_hash, $public_ssl_hash, 'keystone', 'public', 'hostname', [$public_vip])
  $public_auth_port       = '5000'
  $keystone_url           = "${public_auth_protocol}://${public_auth_address}:${public_auth_port}"

  $cinder_options     = {'enable_backup' => pick($storage_hash['volumes_ceph'], false)}
  $neutron_options    = {
    'enable_lb'                 => pick($neutron_advanced_config['neutron_lb'], false),
    'enable_firewall'           => pick($neutron_advanced_config['neutron_firewall'], false),
    'enable_quotas'             => pick($neutron_advanced_config['neutron_quotas'], true),
    'enable_security_group'     => pick($neutron_advanced_config['neutron_security_group'], true),
    'enable_vpn'                => pick($neutron_advanced_config['neutron_vpn'], false),
    'enable_distributed_router' => pick($neutron_advanced_config['neutron_dvr'], false),
    'enable_ha_router'          => pick($neutron_advanced_config['neutron_ha_router'], false),
    'profile_support'           => pick($neutron_advanced_config['neutron_profile_support'], 'None'),
  }
  $hypervisor_options = {'enable_quotas' => hiera('nova_quota')}

  $temp_root_default = '/var/lib/horizon'
  $temp_root_is_dir = inline_template('<%= File.directory?(@temp_root_default) %>')

  if $temp_root_is_dir == 'false' {
    $temp_root_prefix = ''
  }
  else {
    $temp_root_prefix = $temp_root_default
  }

  $file_upload_temp_dir = pick($horizon_hash['upload_dir'], "${temp_root_prefix}/tmp")

  class { '::osnailyfacter::wait_for_keystone_backends':}
  Class['::horizon'] -> Class['::osnailyfacter::wait_for_keystone_backends']

  include ::tweaks::apache_wrappers

  include ::horizon::params

  if pick($horizon_hash['debug'], hiera('debug')) {
    $log_level = 'DEBUG'
  } elsif pick($horizon_hash['verbose'], hiera('verbose', true)) {
    $log_level = 'INFO'
  } else {
    $log_level = 'WARNING'
  }

  # Listen directives with host required for ip_based vhosts
  class { '::osnailyfacter::apache':
    listen_ports => hiera_array('apache_ports', ['0.0.0.0:80', '0.0.0.0:8888']),
  }

  class { '::horizon':
    bind_address          => $bind_address,
    cache_server_ip       => $cache_server_ip,
    cache_server_port     => hiera('memcache_server_port', '11211'),
    cache_backend         => $cache_backend,
    cache_options         => {'SOCKET_TIMEOUT' => 1,'SERVER_RETRIES' => 1,'DEAD_RETRY' => 1},
    secret_key            => $secret_key,
    keystone_url          => $keystone_url,
    listen_ssl            => $use_ssl,
    ssl_no_verify         => $ssl_no_verify,
    log_level             => $log_level,
    configure_apache      => false,
    django_session_engine => 'django.contrib.sessions.backends.cache',
    allowed_hosts         => '*',
    secure_cookies        => false,
    cinder_options        => $cinder_options,
    neutron_options       => $neutron_options,
    custom_theme_path     => $custom_theme_path,
    redirect_type         => 'temp', # LP#1385133
    hypervisor_options    => $hypervisor_options,
    overview_days_range   => $overview_days_range,
    file_upload_temp_dir  => $file_upload_temp_dir,
    api_versions          => {'identity' => 3},
  }

  # Only run collectstatic&compress for MOS packages
  if $repo_type != 'uca' {
    Concat[$::horizon::params::config_file] ~> Exec['refresh_horizon_django_cache']
    Exec['refresh_horizon_django_cache'] -> Exec['refresh_horizon_django_compress']
  }

  # Performance optimization for wsgi
  if ( ($::memorysize_mb + 0) < 1200 or ($::processorcount + 0) <= 3) {
    $wsgi_processes = 2
    $wsgi_threads = 9
  } else {
    $wsgi_processes = $::os_workers
    $wsgi_threads = 15
  }

  $headers = ['set X-XSS-Protection "1; mode=block"',
            'set X-Content-Type-Options nosniff',
            'always append X-Frame-Options SAMEORIGIN']
  $options = '-Indexes'

  # 10G by default
  $file_upload_max_size = pick($horizon_hash['upload_max_size'], 10737418235)

  include ::apache::params

  class { '::horizon::wsgi::apache':
    priority       => false,
    bind_address   => $bind_address,
    wsgi_processes => $wsgi_processes,
    wsgi_threads   => $wsgi_threads,
    listen_ssl     => $use_ssl,
    extra_params   => {
      add_listen        => false,
      ip_based          => true, # Do not setup outdated 'NameVirtualHost' option
      custom_fragment   => template('osnailyfacter/horizon/wsgi_vhost_custom.erb'),
      default_vhost     => true,
      headers           => $headers,
      options           => $options,
      setenvif          => 'X-Forwarded-Proto https HTTPS=1',
      access_log_format => '%{X-Forwarded-For}i %l %u %{%d/%b/%Y:%T}t.%{msec_frac}t \"%r\" %>s %b %D \"%{Referer}i\" \"%{User-Agent}i\"',
    },
  } ~>
  Service[$::apache::params::service_name]

  # Chown dashboard dir
  $dashboard_directory = '/usr/share/openstack-dashboard/'
  $wsgi_user = $::horizon::params::apache_user
  $wsgi_group = $::horizon::params::apache_group

  exec { 'chown_dashboard' :
    command     => "chown -R ${wsgi_user}:${wsgi_group} ${dashboard_directory}",
    path        => [ '/usr/sbin', '/usr/bin', '/sbin', '/bin' ],
    refreshonly => true,
    provider    => 'shell',
  }

  # Refresh cache should be executed only for rpm packages.
  # See I813b5f6067bb6ecce279cab7278d9227c4d31d28 for details.
  if $::os_package_type == 'rpm' {
    Exec['refresh_horizon_django_cache'] ~> Exec['chown_dashboard']
  }

}
