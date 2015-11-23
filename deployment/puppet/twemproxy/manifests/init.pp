# Class: twemproxy
# ===========================
#
# Full description of class twemproxy here.
#
# Parameters
# ----------
#
# Document parameters here.
#
# * `sample parameter`
# Explanation of what this parameter affects and what it defaults to.
# e.g. "Specify one or more upstream ntp servers as an array."
#
# Variables
# ----------
#
# Here you should define a list of variables that this module would require.
#
# * `sample variable`
#  Explanation of how this variable affects the function of this class and if
#  it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#  External Node Classifier as a comma separated list of hostnames." (Note,
#  global variables should be avoided in favor of class parameters as
#  of Puppet 2.6.)
#
# Examples
# --------
#
# @example
#    class { 'twemproxy':
#      servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#    }
#
# Authors
# -------
#
# Stanislaw Bogatkin <sbogatkin@mirantis.com>
#
# Copyright
# ---------
#
# Copyright 2015 Your name here, unless otherwise noted.
#
class twemproxy (
  $package_manage       = $twemproxy::params::package_manage,
  $package_name         = $twemproxy::params::package_name,
  $package_ensure       = $twemproxy::params::package_ensure,
  $service_manage       = $twemproxy::params::service_manage,
  $service_name         = $twemproxy::params::service_name,
  $service_ensure       = $twemproxy::params::service_ensure,
  $service_enable       = $twemproxy::params::service_enable,
  $listen_address       = $twemproxy::params::listen_address,
  $listen_port          = $twemproxy::params::listen_port,
  $timeout              = $twemproxy::params::timeout,
  $backlog              = $twemproxy::params::backlog,
  $preconnect           = $twemproxy::params::preconnect,
  $redis                = $twemproxy::params::redis,
  $redis_auth           = $twemproxy::params::redis_auth,
  $redis_db             = $twemproxy::params::redis_db,
  $server_connections   = $twemproxy::params::server_connections,
  $auto_eject_hosts     = $twemproxy::params::auto_eject_hosts,
  $server_retry_timeout = $twemproxy::params::server_retry_timeout,
  $server_failure_limit = $twemproxy::params::server_failure_limit,
  $client_address       = undef,
  $client_port          = $twemproxy::params::client_port,
  $client_weight        = $twemproxy::params::client_weight,
  $clients_array        = undef,
) inherits twemproxy::params {

  anchor { 'twemproxy::start': } ->
  class { 'twemproxy::install': } ->
  class { 'twemproxy::config': } ->

  twemproxy::pool { 'default':
    listen_address       => $listen_address,
    listen_port          => $listen_port,
    timeout              => $timeout,
    redis                => $redis,
    redis_auth           => $redis_auth,
    server_connections   => $server_connections,
    server_retry_timeout => $server_retry_timeout,
    client_address       => $client_address,
    client_port          => $client_port,
    client_weight        => $client_weight,
    clients_array        => $clients_array,
  } ->

  class { 'twemproxy::service': } ->
  anchor { 'twemproxy::end': }

}
