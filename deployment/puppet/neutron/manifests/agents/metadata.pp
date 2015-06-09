# == Class: neutron::agents::metadata
#
# Setup and configure Neutron metadata agent.
#
# === Parameters
#
# [*auth_password*]
#   (required) The password for the administrative user.
#
# [*shared_secret*]
#   (required) Shared secret to validate proxies Neutron metadata requests.
#
# [*package_ensure*]
#   Ensure state of the package. Defaults to 'present'.
#
# [*enabled*]
#   State of the service. Defaults to true.
#
# [*manage_service*]
#   (optional) Whether to start/stop the service
#   Defaults to true
#
# [*debug*]
#   Debug. Defaults to false.
#
# [*auth_tenant*]
#   The administrative user's tenant name. Defaults to 'services'.
#
# [*auth_user*]
#   The administrative user name for OpenStack Networking.
#   Defaults to 'neutron'.
#
# [*auth_url*]
#   The URL used to validate tokens. Defaults to 'http://localhost:35357/v2.0'.
#
# [*auth_insecure*]
#   turn off verification of the certificate for ssl (Defaults to false)
#
# [*auth_ca_cert*]
#   CA cert to check against with for ssl keystone. (Defaults to undef)
#
# [*auth_region*]
#   The authentication region. Defaults to 'RegionOne'.
#
# [*metadata_ip*]
#   The IP address of the metadata service. Defaults to '127.0.0.1'.
#
# [*metadata_port*]
#   The TCP port of the metadata service. Defaults to 8775.
#
# [*metadata_workers*]
#   (optional) Number of separate worker processes to spawn.
#   The default, count of machine's processors, runs the worker thread in the
#   current process.
#   Greater than 0 launches that number of child processes as workers.
#   The parent process manages them. Having more workers will help to improve performances.
#   Defaults to: $::processorcount
#
# [*metadata_backlog*]
#   (optional) Number of backlog requests to configure the metadata server socket with.
#   Defaults to 4096
#
# [*metadata_memory_cache_ttl*]
#   (optional) Specifies time in seconds a metadata cache entry is valid in
#   memory caching backend.
#   Set to 0 will cause cache entries to never expire.
#   Set to undef or false to disable cache.
#   Defaults to 5
#

class neutron::agents::metadata (
  $auth_password,
  $shared_secret,
  $package_ensure            = 'present',
  $enabled                   = true,
  $manage_service            = true,
  $debug                     = false,
  $auth_tenant               = 'services',
  $auth_user                 = 'neutron',
  $auth_url                  = 'http://localhost:35357/v2.0',
  $auth_insecure             = false,
  $auth_ca_cert              = undef,
  $auth_region               = 'RegionOne',
  $metadata_ip               = '127.0.0.1',
  $metadata_port             = '8775',
  $metadata_workers          = $::processorcount,
  $metadata_backlog          = '4096',
  $metadata_memory_cache_ttl = 5,
  ) {

  include neutron::params

  Package['neutron'] -> Neutron_metadata_agent_config<||>
  Neutron_config<||> ~> Service['neutron-metadata']
  Neutron_metadata_agent_config<||> ~> Service['neutron-metadata']

  neutron_metadata_agent_config {
    'DEFAULT/debug':                          value => $debug;
    'DEFAULT/auth_url':                       value => $auth_url;
    'DEFAULT/auth_insecure':                  value => $auth_insecure;
    'DEFAULT/auth_region':                    value => $auth_region;
    'DEFAULT/admin_tenant_name':              value => $auth_tenant;
    'DEFAULT/admin_user':                     value => $auth_user;
    'DEFAULT/admin_password':                 value => $auth_password, secret => true;
    'DEFAULT/nova_metadata_ip':               value => $metadata_ip;
    'DEFAULT/nova_metadata_port':             value => $metadata_port;
    'DEFAULT/metadata_proxy_shared_secret':   value => $shared_secret;
    'DEFAULT/metadata_workers':               value => $metadata_workers;
    'DEFAULT/metadata_backlog':               value => $metadata_backlog;
  }

  if $metadata_memory_cache_ttl {
    neutron_metadata_agent_config {
      'DEFAULT/cache_url':                    value => "memory://?default_ttl=${metadata_memory_cache_ttl}";
    }
  } else {
    neutron_metadata_agent_config {
      'DEFAULT/cache_url':                   ensure => absent;
    }
  }

  if $auth_ca_cert {
    neutron_metadata_agent_config {
      'DEFAULT/auth_ca_cert':                 value => $auth_ca_cert;
    }
  } else {
    neutron_metadata_agent_config {
      'DEFAULT/auth_ca_cert':                 ensure => absent;
    }
  }

  if $::neutron::params::metadata_agent_package {
    Package['neutron-metadata'] -> Neutron_metadata_agent_config<||>
    Package['neutron-metadata'] -> Service['neutron-metadata']
    package { 'neutron-metadata':
      ensure  => $package_ensure,
      name    => $::neutron::params::metadata_agent_package,
      require => Package['neutron'],
    }
  }

  if $manage_service {
    if $enabled {
      $service_ensure = 'running'
    } else {
      $service_ensure = 'stopped'
    }
  }

  service { 'neutron-metadata':
    ensure  => $service_ensure,
    name    => $::neutron::params::metadata_agent_service,
    enable  => $enabled,
    require => Class['neutron'],
  }
}
