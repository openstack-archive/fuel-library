#
# Class to serve keystone with apache mod_wsgi in place of keystone service
#
# Serving keystone from apache is the recommended way to go for production
# systems as the current keystone implementation is not multi-processor aware,
# thus limiting the performance for concurrent accesses.
#
# See the following URIs for reference:
#    https://etherpad.openstack.org/havana-keystone-performance
#    http://adam.younglogic.com/2012/03/keystone-should-move-to-apache-httpd/
#
# When using this class you should disable your keystone service.
#
# == Parameters
#
#   [*servername*]
#     The servername for the virtualhost.
#     Optional. Defaults to $::fqdn
#
#   [*public_port*]
#     The public port.
#     Optional. Defaults to 5000
#
#   [*admin_port*]
#     The admin port.
#     Optional. Defaults to 35357
#
#   [*bind_host*]
#     The host/ip address Apache will listen on.
#     Optional. Defaults to undef (listen on all ip addresses).
#
#   [*public_path*]
#     The prefix for the public endpoint.
#     Optional. Defaults to '/'
#
#   [*admin_path*]
#     The prefix for the admin endpoint.
#     Optional. Defaults to '/'
#
#   [*ssl*]
#     Use ssl ? (boolean)
#     Optional. Defaults to true
#
#   [*workers*]
#     Number of WSGI workers to spawn.
#     Optional. Defaults to 1
#
#   [*ssl_cert*]
#   [*ssl_key*]
#   [*ssl_chain*]
#   [*ssl_ca*]
#   [*ssl_crl_path*]
#   [*ssl_crl*]
#   [*ssl_certs_dir*]
#     apache::vhost ssl parameters.
#     Optional. Default to apache::vhost 'ssl_*' defaults.
#
# == Dependencies
#
#   requires Class['apache'] & Class['keystone']
#
# == Examples
#
#   include apache
#
#   class { 'keystone::wsgi::apache': }
#
# == Note about ports & paths
#
#   When using same port for both endpoints (443 anyone ?), you *MUST* use two
#  different public_path & admin_path !
#
# == Authors
#
#   François Charlier <francois.charlier@enovance.com>
#
# == Copyright
#
#   Copyright 2013 eNovance <licensing@enovance.com>
#
class keystone::wsgi::apache (
  $servername         = $::fqdn,
  $public_port        = 5000,
  $admin_port         = 35357,
  $bind_host          = undef,
  $public_path        = '/',
  $admin_path         = '/',
  $ssl                = true,
  $workers            = 1,
  $ssl_cert           = undef,
  $ssl_key            = undef,
  $ssl_chain          = undef,
  $ssl_ca             = undef,
  $ssl_crl_path       = undef,
  $ssl_crl            = undef,
  $ssl_certs_dir      = undef,
  $threads            = $::processorcount,
  $priority           = '10',
  $wsgi_script_ensure = 'file',
  $wsgi_script_source = undef,
) {

  include keystone::params
  include ::apache
  include ::apache::mod::wsgi
  include keystone::db::sync

  Exec <| title == 'keystone-manage pki_setup' |> ~> Service['httpd']
  Exec <| title == 'keystone-manage db_sync' |> ~> Service['httpd']
  Package['keystone'] ~> Service['httpd']
  Keystone_config <| |> ~> Service['httpd']
  Service['httpd'] -> Keystone_endpoint <| |>
  Service['httpd'] -> Keystone_role <| |>
  Service['httpd'] -> Keystone_service <| |>
  Service['httpd'] -> Keystone_tenant <| |>
  Service['httpd'] -> Keystone_user <| |>
  Service['httpd'] -> Keystone_user_role <| |>

  ## Sanitize parameters

  # Ensure there's no trailing '/' except if this is also the only character
  $public_path_real = regsubst($public_path, '(^/.*)/$', '\1')
  # Ensure there's no trailing '/' except if this is also the only character
  $admin_path_real = regsubst($admin_path, '(^/.*)/$', '\1')

  if $public_port == $admin_port and $public_path_real == $admin_path_real {
    fail('When using the same port for public & private endpoints, public_path and admin_path should be different.')
  }

  file { $::keystone::params::keystone_wsgi_script_path:
    ensure  => directory,
    owner   => 'keystone',
    group   => 'keystone',
    require => Package['httpd'],
  }

  $wsgi_files = {
    'keystone_wsgi_admin' => {
      'path' => "${::keystone::params::keystone_wsgi_script_path}/admin",
    },
    'keystone_wsgi_main'  => {
      'path' => "${::keystone::params::keystone_wsgi_script_path}/main",
    },
  }

  $wsgi_file_defaults = {
    'ensure'  => $wsgi_script_ensure,
    'owner'   => 'keystone',
    'group'   => 'keystone',
    'mode'    => '0644',
    'require' => File[$::keystone::params::keystone_wsgi_script_path],
  }

  $wsgi_script_source_real = $wsgi_script_source ? {
    default => $wsgi_script_source,
    undef   => $::keystone::params::keystone_wsgi_script_source,
  }

  case $wsgi_script_ensure {
    default: { $wsgi_file_source = { 'source' => $wsgi_script_source_real } }
    'link':  { $wsgi_file_source = { 'target' => $wsgi_script_source_real } }
  }

  create_resources('file', $wsgi_files, merge($wsgi_file_defaults, $wsgi_file_source))

  $wsgi_daemon_process_options = {
    user      => 'keystone',
    group     => 'keystone',
    processes => $workers,
    threads   => $threads
  }
  $wsgi_script_aliases_main = hash([$public_path_real,"${::keystone::params::keystone_wsgi_script_path}/main"])
  $wsgi_script_aliases_admin = hash([$admin_path_real, "${::keystone::params::keystone_wsgi_script_path}/admin"])

  if $public_port == $admin_port {
    $wsgi_script_aliases_main_real = merge($wsgi_script_aliases_main, $wsgi_script_aliases_admin)
  } else {
    $wsgi_script_aliases_main_real = $wsgi_script_aliases_main
  }

  apache::vhost { 'keystone_wsgi_main':
    servername                  => $servername,
    ip                          => $bind_host,
    port                        => $public_port,
    docroot                     => $::keystone::params::keystone_wsgi_script_path,
    docroot_owner               => 'keystone',
    docroot_group               => 'keystone',
    priority                    => $priority,
    ssl                         => $ssl,
    ssl_cert                    => $ssl_cert,
    ssl_key                     => $ssl_key,
    ssl_chain                   => $ssl_chain,
    ssl_ca                      => $ssl_ca,
    ssl_crl_path                => $ssl_crl_path,
    ssl_crl                     => $ssl_crl,
    ssl_certs_dir               => $ssl_certs_dir,
    wsgi_daemon_process         => 'keystone_main',
    wsgi_daemon_process_options => $wsgi_daemon_process_options,
    wsgi_process_group          => 'keystone_main',
    wsgi_script_aliases         => $wsgi_script_aliases_main_real,
    require                     => [Class['apache::mod::wsgi'], File['keystone_wsgi_main']],
  }

  if $public_port != $admin_port {
    apache::vhost { 'keystone_wsgi_admin':
      servername                  => $servername,
      ip                          => $bind_host,
      port                        => $admin_port,
      docroot                     => $::keystone::params::keystone_wsgi_script_path,
      docroot_owner               => 'keystone',
      docroot_group               => 'keystone',
      priority                    => $priority,
      ssl                         => $ssl,
      ssl_cert                    => $ssl_cert,
      ssl_key                     => $ssl_key,
      ssl_chain                   => $ssl_chain,
      ssl_ca                      => $ssl_ca,
      ssl_crl_path                => $ssl_crl_path,
      ssl_crl                     => $ssl_crl,
      ssl_certs_dir               => $ssl_certs_dir,
      wsgi_daemon_process         => 'keystone_admin',
      wsgi_daemon_process_options => $wsgi_daemon_process_options,
      wsgi_process_group          => 'keystone_admin',
      wsgi_script_aliases         => $wsgi_script_aliases_admin,
      require                     => [Class['apache::mod::wsgi'], File['keystone_wsgi_admin']],
    }
  }
}
