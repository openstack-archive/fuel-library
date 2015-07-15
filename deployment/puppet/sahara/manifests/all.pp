# == Class: sahara::all
#
# Installs & configure the Sahara combined API & Engine service
# Deprecated since Kilo
#
# === Parameters
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
class sahara::all (
  $enabled           = true,
  $host              = '0.0.0.0',
  $manage_service    = true,
  $package_ensure    = 'present',
  $port              = '8386',
) {

  include ::sahara
  include ::sahara::params
  include ::sahara::policy

  Sahara_config<||> ~> Service['sahara-all']
  Class['sahara::policy'] -> Service['sahara-all']
  Package<| title == 'sahara-common' |> -> Package['sahara-all']
  Exec['sahara-dbmanage'] -> Service['sahara-all']

  package { 'sahara-all':
    ensure => $package_ensure,
    name   => $::sahara::params::all_package_name,
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
    'DEFAULT/host': value => $host;
    'DEFAULT/port': value => $port;
  }

  service { 'sahara-all':
    ensure     => $service_ensure,
    name       => $::sahara::params::all_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    require    => Package['sahara-all'],
  }

}
