# == Class: heat::api_cfn
#
# This class deprecates heat::api-cfn.
#
# Installs & configure the heat CloudFormation API service
#
# === Parameters
#
# [*package_ensure*]
#    (Optional) Ensure state for package.
#    Defaults to 'present'
#
# [*enabled*]
#   (optional) Should the service be enabled.
#   Defaults to 'true'.
#
# [*manage_service*]
#   (optional) Whether the service should be managed by Puppet.
#   Defaults to 'true'.
#
# [*bind_host*]
#   (Optional) Address to bind the server. Useful when
#   selecting a particular network interface.
#   Defaults to '0.0.0.0'.
#
# [*bind_port*]
#   (Optional) The port on which the server will listen.
#   Defaults to '8000'.
#
# [*workers*]
#   (Optional) The port on which the server will listen.
#   Defaults to '0'.
#
# [*use_ssl*]
#   (Optional) Whether to use ssl or not.
#   Defaults to 'false'.
#
# [*cert_file*]
#   (Optional) Location of the SSL certificate file to use for SSL mode.
#   Required when $use_ssl is set to 'true'.
#   Defaults to 'false'.
#
# [*key_file*]
#   (Optional) Location of the SSL key file to use for enabling SSL mode.
#   Required when $use_ssl is set to 'true'.
#   Defaults to 'false'.
#
# == Deprecated Parameters
#
# No Deprecated Parameters.
#
class heat::api_cfn (
  $package_ensure    = 'present',
  $manage_service    = true,
  $enabled           = true,
  $bind_host         = '0.0.0.0',
  $bind_port         = '8000',
  $workers           = '0',
  $use_ssl           = false,
  $cert_file         = false,
  $key_file          = false,
) {

  include ::heat
  include ::heat::params
  include ::heat::policy

  Heat_config<||> ~> Service['heat-api-cfn']
  Class['heat::policy'] -> Service['heat-api-cfn']

  Package['heat-api-cfn'] -> Heat_config<||>
  Package['heat-api-cfn'] -> Class['heat::policy']
  Package['heat-api-cfn'] -> Service['heat-api-cfn']

  if $use_ssl {
    if !$cert_file {
      fail('The cert_file parameter is required when use_ssl is set to true')
    }
    if !$key_file {
      fail('The key_file parameter is required when use_ssl is set to true')
    }
  }

  package { 'heat-api-cfn':
    ensure => $package_ensure,
    name   => $::heat::params::api_cfn_package_name,
    tag    => 'openstack',
  }

  if $manage_service {
    if $enabled {
      $service_ensure = 'running'
    } else {
      $service_ensure = 'stopped'
    }
  }

  Package['heat-common'] -> Service['heat-api-cfn']

  service { 'heat-api-cfn':
    ensure     => $service_ensure,
    name       => $::heat::params::api_cfn_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    subscribe  => $::heat::subscribe_sync_db,
  }

  heat_config {
    'heat_api_cfn/bind_host'              : value => $bind_host;
    'heat_api_cfn/bind_port'              : value => $bind_port;
    'heat_api_cfn/workers'                : value => $workers;
  }

  # SSL Options
  if $use_ssl {
    heat_config {
      'heat_api_cfn/cert_file' : value => $cert_file;
      'heat_api_cfn/key_file' :  value => $key_file;
    }
  } else {
    heat_config {
      'heat_api_cfn/cert_file' : ensure => absent;
      'heat_api_cfn/key_file' :  ensure => absent;
    }
  }

}
