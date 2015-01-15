# == Class: horizon::wsgi::apache
#
# Configures Apache WSGI for Horizon.
#
# === Parameters
#
#  [*bind_address*]
#    (optional) Bind address in Apache for Horizon. (Defaults to '0.0.0.0')
#
#  [*server_aliases*]
#    (optional) List of names which should be defined as ServerAlias directives
#    in vhost.conf.
#    Defaults to ::fqdn.
#
#  [*listen_ssl*]
#    (optional) Enable SSL support in Apache. (Defaults to false)
#
#  [*horizon_cert*]
#    (required with listen_ssl) Certificate to use for SSL support.
#
#  [*horizon_key*]
#    (required with listen_ssl) Private key to use for SSL support.
#
#  [*horizon_ca*]
#    (required with listen_ssl) CA certificate to use for SSL support.
#
#  [*wsgi_processes*]
#    (optional) Number of Horizon processes to spawn
#    Defaults to '3'
#
#  [*wsgi_threads*]
#    (optional) Number of thread to run in a Horizon process
#    Defaults to '10'
#
#  [*priority*]
#    (optional) The apache vhost priority.
#    Defaults to '15'. To set Horizon as the primary vhost, change to '10'.
#
#  [*extra_params*]
#    (optional) A hash of extra paramaters for apache::wsgi class.
#    Defaults to {}
class horizon::wsgi::apache (
  $bind_address        = undef,
  $fqdn                = undef,
  $servername          = $::fqdn,
  $server_aliases      = $::fqdn,
  $listen_ssl          = false,
  $ssl_redirect        = true,
  $horizon_cert        = undef,
  $horizon_key         = undef,
  $horizon_ca          = undef,
  $wsgi_processes      = '3',
  $wsgi_threads        = '10',
  $priority            = '15',
  $vhost_conf_name     = 'horizon_vhost',
  $vhost_ssl_conf_name = 'horizon_ssl_vhost',
  $extra_params        = {},
) {

  include ::horizon::params
  include ::apache

  if $fqdn {
    warning('Parameter fqdn is deprecated. Please use parameter server_aliases for setting ServerAlias directives in vhost.conf.')
    $final_server_aliases = $fqdn
  } else {
    $final_server_aliases = $server_aliases
  }

  include ::apache::mod::wsgi

  # We already use apache::vhost to generate our own
  # configuration file, let's clean the configuration
  # embedded within the package
  file { $::horizon::params::httpd_config_file:
    ensure  => present,
    content => "#
# This file has been cleaned by Puppet.
#
# OpenStack Horizon configuration has been moved to:
# - ${priority}-${vhost_conf_name}.conf
# - ${priority}-${vhost_ssl_conf_name}.conf
#",
    require => Package[$::horizon::params::package_name]
  }


  if $listen_ssl {
    include ::apache::mod::ssl
    $ensure_ssl_vhost = 'present'

    if $horizon_ca == undef {
      fail('The horizon_ca parameter is required when listen_ssl is true')
    }

    if $horizon_cert == undef {
      fail('The horizon_cert parameter is required when listen_ssl is true')
    }

    if $horizon_key == undef {
      fail('The horizon_key parameter is required when listen_ssl is true')
    }

    if $ssl_redirect {
      $redirect_match = '(.*)'
      $redirect_url   = "https://${servername}"
    }

  } else {
    $ensure_ssl_vhost = 'absent'
    $redirect_match = '^/$'
    $redirect_url   = $::horizon::params::root_url
  }

  Package['horizon'] -> Package[$::horizon::params::http_service]
  File[$::horizon::params::config_file] ~> Service[$::horizon::params::http_service]

  $unix_user = $::osfamily ? {
    'RedHat' => $::horizon::params::apache_user,
    default  => $::horizon::params::wsgi_user
  }
  $unix_group = $::osfamily ? {
    'RedHat' => $::horizon::params::apache_group,
    default  => $::horizon::params::wsgi_group,
  }

  file { $::horizon::params::logdir:
    ensure       => directory,
    owner        => $unix_user,
    group        => $unix_group,
    before       => Service[$::horizon::params::http_service],
    mode         => '0751',
    require      => Package['horizon']
  }

  file { "${::horizon::params::logdir}/horizon.log":
    ensure       => file,
    owner        => $unix_user,
    group        => $unix_group,
    before       => Service[$::horizon::params::http_service],
    mode         => '0640',
    require      => [ File[$::horizon::params::logdir], Package['horizon'] ],
  }

  $default_vhost_conf_no_ip = {
    servername           => $servername,
    serveraliases        => os_any2array($final_server_aliases),
    docroot              => '/var/www/',
    access_log_file      => 'horizon_access.log',
    error_log_file       => 'horizon_error.log',
    priority             => $priority,
    aliases              => [
      { alias => '/static', path => '/usr/share/openstack-dashboard/static' }
    ],
    port                 => 80,
    ssl_cert             => $horizon_cert,
    ssl_key              => $horizon_key,
    ssl_ca               => $horizon_ca,
    wsgi_script_aliases  => hash([$::horizon::params::root_url, $::horizon::params::django_wsgi]),
    wsgi_daemon_process  => $::horizon::params::wsgi_group,
    wsgi_daemon_process_options => {
      processes    => $wsgi_processes,
      threads      => $wsgi_threads,
      user         => $unix_user,
      group        => $unix_group,
    },
    wsgi_import_script   => $::horizon::params::django_wsgi,
    wsgi_process_group   => $::horizon::params::wsgi_group,
    redirectmatch_status => 'permanent',
  }

  # Only add the 'ip' element to the $default_vhost_conf hash if it was explicitly
  # specified in the instantiation of the class.  This is because ip => undef gets
  # changed to ip => '' via the Puppet function API when ensure_resource is called.
  # See https://bugs.launchpad.net/puppet-horizon/+bug/1371345
  if $bind_address {
    $default_vhost_conf = merge($default_vhost_conf_no_ip, { ip => $bind_address })
  } else {
    $default_vhost_conf = $default_vhost_conf_no_ip
  }

  ensure_resource('apache::vhost', $vhost_conf_name, merge ($default_vhost_conf, $extra_params, {
    redirectmatch_regexp => $redirect_match,
    redirectmatch_dest   => $redirect_url,
  }))
  ensure_resource('apache::vhost', $vhost_ssl_conf_name, merge ($default_vhost_conf, $extra_params, {
    access_log_file      => 'horizon_ssl_access.log',
    error_log_file       => 'horizon_ssl_error.log',
    priority             => $priority,
    ssl                  => true,
    port                 => 443,
    ensure               => $ensure_ssl_vhost,
    wsgi_daemon_process  => 'horizon-ssl',
    wsgi_process_group   => 'horizon-ssl',
    redirectmatch_regexp => '^/$',
    redirectmatch_dest   => $::horizon::params::root_url,
  }))

}
