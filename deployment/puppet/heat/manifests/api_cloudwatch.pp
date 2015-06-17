# == Class: heat::api_cloudwatch
#
# This class deprecates heat::api-cloudwatch
#
# Installs & configure the heat CloudWatch API service
#
# === Parameters
# [*package_ensure*]
#    (Optional) Ensure state for package.
#    Defaults to 'present'
#
# [*enabled*]
#   (optional) Should the service be enabled.
#   Defaults to true.
#
# [*manage_service*]
#   (optional) Whether the service should be managed by Puppet.
#   Defaults to true.
#
# [*bind_host*]
#   (Optional) Address to bind the server. Useful when
#   selecting a particular network interface.
#   Defaults to '0.0.0.0'.
#
# [*bind_port*]
#   (Optional) The port on which the server will listen.
#   Defaults to '8003'.
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
class heat::api_cloudwatch (
  $package_ensure    = 'present',
  $manage_service    = true,
  $enabled           = true,
  $bind_host         = '0.0.0.0',
  $bind_port         = '8003',
  $workers           = '0',
  $use_ssl           = false,
  $cert_file         = false,
  $key_file          = false,
) {

  include ::heat
  include ::heat::params
  include ::heat::policy

  Heat_config<||> ~> Service['heat-api-cloudwatch']
  Class['heat::policy'] -> Service['heat-api-cloudwatch']

  Package['heat-api-cloudwatch'] -> Heat_config<||>
  Package['heat-api-cloudwatch'] -> Class['heat::policy']
  Package['heat-api-cloudwatch'] -> Service['heat-api-cloudwatch']

  if $use_ssl {
    if !$cert_file {
      fail('The cert_file parameter is required when use_ssl is set to true')
    }
    if !$key_file {
      fail('The key_file parameter is required when use_ssl is set to true')
    }
  }

  package { 'heat-api-cloudwatch':
    ensure => $package_ensure,
    name   => $::heat::params::api_cloudwatch_package_name,
    tag    => 'openstack',
  }

  if $manage_service {
    if $enabled {
      $service_ensure = 'running'
    } else {
      $service_ensure = 'stopped'
    }
  }


  Package['heat-common'] -> Service['heat-api-cloudwatch']

  service { 'heat-api-cloudwatch':
    ensure     => $service_ensure,
    name       => $::heat::params::api_cloudwatch_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    subscribe  => $::heat::subscribe_sync_db,
  }

  heat_config {
    'heat_api_cloudwatch/bind_host'  : value => $bind_host;
    'heat_api_cloudwatch/bind_port'  : value => $bind_port;
    'heat_api_cloudwatch/workers'    : value => $workers;
  }

  # SSL Options
  if $use_ssl {
    heat_config {
      'heat_api_cloudwatch/cert_file' : value => $cert_file;
      'heat_api_cloudwatch/key_file' :  value => $key_file;
    }
  } else {
    heat_config {
      'heat_api_cloudwatch/cert_file' : ensure => absent;
      'heat_api_cloudwatch/key_file' :  ensure => absent;
    }
  }

}
