#
# TODO - assumes that proxy server is always a memcached server
#
# TODO - the full list of all things that can be configured is here
#  https://github.com/openstack/swift/tree/master/swift/common/middleware
#
# Installs and configures the swift proxy node.
#
# [*Parameters*]
#
# [*proxy_local_net_ip*] The address that the proxy will bind to.
#   Required.
# [*port*] The port to which the proxy server will bind.
#   Optional. Defaults to 8080.
# [*workers*] Number of threads to process requests.
#  Optional. Defaults to the number of processors.
# [*auth_type*] - Type of authorization to use.
#  valid values are tempauth, swauth, and keystone.
#  Optional. Defaults to tempauth.
# [*allow_account_management*]
#   Rather or not requests through this proxy can create and
#   delete accounts. Optional. Defaults to true.
# [*account_autocreate*] Rather accounts should automatically be created.
#  Has to be set to true for tempauth. Optional. Defaults to true.
# [*proxy_port*] Port that the swift proxy service will bind to.
#   Optional. Defaults to 11211
# [*package_ensure*] Ensure state of the swift proxy package.
#   Optional. Defaults to present.
# [*cache_servers*] A list of the memcache servers to be used. Entries
#  should be in the form host:port.
# == sw auth specific configuration
# [*swauth_endpoint*]
# [*swauth_super_admin_user*]
#
# == Dependencies
#
#   Class['memcached']
#
# == Examples
#
# == Authors
#
#   Dan Bode dan@puppetlabs.com
#
# == Copyright
#
# Copyright 2011 Puppetlabs Inc, unless otherwise noted.
#
class swift::proxy(
  $proxy_local_net_ip,
  $port = '8080',
  $workers = $::processorcount,
  $cache_servers = ['127.0.0.1:11211'],
  $allow_account_management = true,
  $auth_type = 'tempauth',
  $account_autocreate = true,
  $swauth_endpoint = '127.0.0.1',
  $swauth_super_admin_key = 'swauthkey',
  $package_ensure = 'present'
) inherits swift {

  validate_bool($account_autocreate)
  validate_bool($allow_account_management)
  validate_re($auth_type, 'tempauth|swauth|keystone')

  if($auth_type == 'tempauth' and ! $account_autocreate ){
    fail("\$account_autocreate must be set to true when auth type is tempauth")
  }

  if $cache_server_ips =~ /^127\.0\.0\.1/ {
    Class['memcached'] -> Class['swift::proxy']
  }

  if(auth_type == 'keystone') {
    fail('Keystone is currently not supported, it should be supported soon :)')
  }

  package { 'swift-proxy':
    name   => $::swift::params::proxy_package_name,
    ensure => $package_ensure,
  }

  if($auth_type == 'swauth') {
    package { 'python-swauth':
      ensure  => $package_ensure,
      before  => Package['swift-proxy'],
    }
  }

  file { "/etc/swift/proxy-server.conf":
    ensure  => present,
    owner   => 'swift',
    group   => 'swift',
    mode    => 0660,
    content => template('swift/proxy-server.conf.erb'),
    require => Package['swift-proxy'],
  }

  if($::operatingsystem == 'Ubuntu') {
    # TODO - this needs to be updated once the init file is not broken
    file { '/etc/init/swift-proxy.conf':
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      content => '
# swift-proxy - SWIFT Proxy Server
# This is temporarily managed by Puppet
# until 917893 is fixed
# The swift proxy server.

description     "SWIFT Proxy Server"
author          "Marc Cluet <marc.cluet@ubuntu.com>"

start on runlevel [2345]
stop on runlevel [016]

pre-start script
  if [ -f "/etc/swift/proxy-server.conf" ]; then
    exec /usr/bin/swift-init proxy-server start
  else
    exit 1
  fi
end script

post-stop exec /usr/bin/swift-init proxy-server stop',
      before => Service['swift-proxy'],
    }
  }

  service { 'swift-proxy':
    name      => $::swift::params::proxy_service_name,
    ensure    => running,
    provider  => $::swift::params::service_provider,
    enable    => true,
    subscribe => File['/etc/swift/proxy-server.conf'],
  }
}
