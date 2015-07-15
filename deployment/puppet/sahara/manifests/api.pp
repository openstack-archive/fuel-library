# == Class: sahara::api
#
# Installs & configure the Sahara API service
#
# === Parameters
# [*api_workers*]
#   (Optional) Number of workers for Sahara API service
#   0 means all-in-one-thread configuration
#   Defaults to undef.
#
# [*enabled*]
#   (Optional) Should the service be enabled.
#   Defaults to 'true'.
#
# [*host*]
#   (Optional) Hostname for sahara to listen on
#   Defaults to '0.0.0.0'.
#
# [*manage_service*]
#   (Optional) Whether the service should be managed by Puppet.
#   Defaults to 'true'.
#
# [*package_ensure*]
#   (Optional) Ensure state for package.
#   Defaults to 'present'
#
# [*port*]
#   (Optional) Port for sahara to listen on
#   Defaults to 8386.
#
class sahara::api (
  $api_workers       = 0,
  $enabled           = true,
  $host              = '0.0.0.0',
  $manage_service    = true,
  $package_ensure    = 'present',
  $port              = '8386',
) {

  include ::sahara
  include ::sahara::params
  include ::sahara::policy

  Sahara_config<||> ~> Service['sahara-api']
  Package<| title == 'sahara-common' |> -> Package['sahara-api']
  Exec['sahara-dbmanage'] -> Service['sahara-api']
  Class['sahara::policy'] -> Service['sahara-api']

  package { 'sahara-api':
    ensure => $package_ensure,
    name   => $::sahara::params::api_package_name,
    tag    => 'openstack',
  }

  if $manage_service {
    if $enabled {
      $service_ensure = 'running'
    } else {
      $service_ensure = 'stopped'
    }
  }

  sahara_config {
    'DEFAULT/api_workers': value => $api_workers;
    'DEFAULT/host':        value => $host;
    'DEFAULT/port':        value => $port;
  }

  service { 'sahara-api':
    ensure     => $service_ensure,
    name       => $::sahara::params::api_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    require    => Package['sahara-api'],
  }

}
