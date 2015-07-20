# == Class: murano::engine
#
#  murano engine package & service
#
# === Parameters
#
# [*manage_service*]
#  (Optional) Should the service be enabled
#  Defaults to true
#
# [*enabled*]
#  (Optional) Whether the service should be managed by Puppet
#  Defaults to true
#
# [*package_ensure*]
#  (Optional) Ensure state for package
#  Defaults to 'present'
#
class murano::engine(
  $manage_service = true,
  $enabled        = true,
  $package_ensure = 'present',
) {

  include ::murano
  include ::murano::params
  include ::murano::policy

  Murano_config<||> ~> Service['murano-engine']
  Exec['murano-dbmanage'] -> Service['murano-engine']
  Class['murano::policy'] -> Service['murano-engine']

  if $manage_service {
    if $enabled {
      $service_ensure = 'running'
    } else {
      $service_ensure = 'stopped'
    }
  }

  package { 'murano-engine':
    ensure => $package_ensure,
    name   => $::murano::params::engine_package_name,
  }

  service { 'murano-engine':
    ensure  => $service_ensure,
    name    => $::murano::params::engine_service_name,
    enable  => $enabled,
    require => Package['murano-engine'],
  }

  Package['murano-engine'] ~> Service['murano-engine']
  Murano_paste_ini_config<||> ~> Service['murano-engine']

}
