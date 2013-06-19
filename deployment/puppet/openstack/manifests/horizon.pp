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
  $bind_address          = '127.0.0.1',
  $cache_server_ip       = '127.0.0.1',
  $cache_server_port     = '11211',
  $swift                 = false,
  $quantum               = false,
  $horizon_app_links     = undef,
  $keystone_host         = '127.0.0.1',
  $keystone_scheme       = 'http',
  $keystone_default_role = 'Member',
  $verbose               = 'false',
  $api_result_limit      = 1000,
  $package_ensure        = present,
  $use_ssl               = false,
) {

  # class { 'memcached':
  #  listen_ip => $cache_server_ip,
  #  tcp_port  => $cache_server_port,
  #  udp_port  => $cache_server_port,
  # }
 if $verbose =~ /(?i)(true|yes)/
 {
   $django_debug = 'True'
 }
 else
 {
   $django_debug = 'False'
 }

  class { '::horizon':
    bind_address          => $bind_address,
    cache_server_ip       => $cache_server_ip,
    cache_server_port     => $cache_server_port,
    secret_key            => $secret_key,
    swift                 => $swift,
    quantum               => $quantum,
    package_ensure        => $package_ensure,
    horizon_app_links     => $horizon_app_links,
    keystone_host         => $keystone_host,
    keystone_scheme       => $keystone_scheme,
    keystone_default_role => $keystone_default_role,
    django_debug          => $django_debug,
    api_result_limit      => $api_result_limit,
    use_ssl               => $use_ssl,
  }
}
