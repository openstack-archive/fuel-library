# == Class: sahara::engine
#
# Installs & configure the Sahara Engine service
#
# === Parameters
# [*enabled*]
#   (Optional) Should the service be enabled.
#   Defaults to 'true'.
#
# [*infrastructure_engine*]
#   (Optional) An engine which will be used to provision
#   infrastructure for Hadoop cluster.
#   Can be set to 'direct' and 'heat'
#   Defaults to 'direct'
#
# [*manage_service*]
#   (Optional) Whether the service should be managed by Puppet.
#   Defaults to 'true'.
#
# [*package_ensure*]
#   (Optional) Ensure state for package.
#   Defaults to 'present'
#
class sahara::engine (
  $enabled               = true,
  $infrastructure_engine = 'direct',
  $manage_service        = true,
  $package_ensure        = 'present',
) {

  include ::sahara
  include ::sahara::params
  include ::sahara::policy

  Sahara_config<||> ~> Service['sahara-engine']
  Package<| title == 'sahara-common' |> -> Package['sahara-engine']
  Class['sahara::policy'] -> Service['sahara-engine']

  package { 'sahara-engine':
    ensure => $package_ensure,
    name   => $::sahara::params::engine_package_name,
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
    'DEFAULT/infrastructure_engine': value => $infrastructure_engine;
  }

  service { 'sahara-engine':
    ensure     => $service_ensure,
    name       => $::sahara::params::engine_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    require    => Package['sahara-engine'],
  }

}
