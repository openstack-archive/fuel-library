#
# == Class: openstack::horizon
#
# Class to install / configure horizon.
# Will eventually include apache and ssl.
#
# NOTE: Will the inclusion of memcache be an issue?
#       Such as if the server already has memcache installed?
#       -jtopjian
#
# === Parameters
#
# See params.pp
#
# === Examples
#
# class { 'openstack::horizon':
#   secret_key => 'dummy_secret_key',
# }
#

class openstack::horizon (
  $secret_key,
  $bind_address            = '127.0.0.1',
  $cache_server_ip         = '127.0.0.1',
  $cache_server_port       = '11211',
  $swift                   = false,
  $neutron                 = false,
  $neutron_options         = {},
  $horizon_app_links       = undef,
  $keystone_host           = '127.0.0.1',
  $keystone_scheme         = 'http',
  $keystone_default_role   = '_member_',
  $verbose                 = false,
  $debug                   = false,
  $api_result_limit        = 1000,
  $package_ensure          = present,
  $use_ssl                 = false,
  $use_syslog              = false,
  $log_level               = 'WARNING',
  $nova_quota              = false,
  $local_settings_template = 'openstack/horizon/local_settings.py.erb',
  $django_session_engine   = 'django.contrib.sessions.backends.cache',
  $servername              = $::hostname,
) {

  if $debug { #syslog and nondebug case
    #We don't realy want django debug, it is too verbose.
    $django_debug   = false
    $django_verbose = false
    $log_level_real = 'DEBUG'
  } elsif $verbose {
    $django_verbose = true
    $django_debug   = false
    $log_level_real = 'INFO'
  } else {
    $django_verbose = false
    $django_debug   = false
    $log_level_real = $log_level
  }

  # Performance optimization for wsgi
  if ($::memorysize_mb < 1200 or $::processorcount <= 3) {
    $wsgi_processes = 2
    $wsgi_threads = 9
  } else {
    $wsgi_processes = $::processorcount
    $wsgi_threads = 15
  }

  # Performance optimization for Apache mpm
  if $::memorysize_mb < 4100 {
    $maxclients = 100
  } else {
    $maxclients = inline_template('<%= Integer(@memorysize_mb.to_i / 10) %>')
  }

  if $::processorcount <= 2 {
    $startservers = 2
  } else {
    $startservers = $::processorcount
  }

  $maxrequestsperchild = 0
  $threadsperchild     = 25
  $minsparethreads     = 25
  $serverlimit         = inline_template('<%= Integer(@maxclients.to_i / @threadsperchild.to_i) %>')
  $maxsparethreads     = inline_template('<%= Integer(@maxclients.to_i / 2) %>')

  # Define apache mpm
  if $::osfamily == 'RedHat' {
    $mpm_module = 'event'
  } else {
    $mpm_module = 'worker'
  }

  class { '::apache':
    mpm_module    => false,
    default_vhost => false,
    servername    => $servername,
  }

  class { "::apache::mod::$mpm_module":
    startservers        => $startservers,
    maxclients          => $maxclients,
    minsparethreads     => $minsparethreads,
    maxsparethreads     => $maxsparethreads,
    threadsperchild     => $threadsperchild,
    maxrequestsperchild => $maxrequestsperchild,
    serverlimit         => $serverlimit,
  }

  class { '::horizon':
    bind_address            => $bind_address,
    cache_server_ip         => $cache_server_ip,
    cache_server_port       => $cache_server_port,
    secret_key              => $secret_key,
    swift                   => $swift,
    package_ensure          => $package_ensure,
    horizon_app_links       => $horizon_app_links,
    keystone_host           => $keystone_host,
    keystone_scheme         => $keystone_scheme,
    keystone_default_role   => $keystone_default_role,
    django_debug            => $django_debug,
    api_result_limit        => $api_result_limit,
    listen_ssl              => $use_ssl,
    log_level               => $log_level_real,
    local_settings_template => $local_settings_template,
    configure_apache        => false,
    django_session_engine   => $django_session_engine,
    allowed_hosts           => '*',
    secure_cookies          => false,
    neutron_options         => $neutron_options,
  }

  class { '::horizon::wsgi::apache':
    priority       => false,
    bind_address   => "*",
    wsgi_processes => $wsgi_processes,
    wsgi_threads   => $wsgi_threads,
    listen_ssl     => $use_ssl,
    extra_params      => {
      default_vhost   => true,
      custom_fragment => template("openstack/horizon/wsgi_vhost_custom.erb"),
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

  Exec['refresh_horizon_django_cache'] ~> Exec['chown_dashboard']
}

