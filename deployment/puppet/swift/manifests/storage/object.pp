# Class swift::storage::object
#
# == Parameters
#  [*enabled*]
#    (optional) Should the service be enabled.
#    Defaults to true
#
#  [*manage_service*]
#    (optional) Whether the service should be managed by Puppet.
#    Defaults to true.
#
#  [*package_ensure*]
#    (optional) Value of package resource parameter 'ensure'.
#    Defaults to 'present'.
#
class swift::storage::object(
  $manage_service = true,
  $enabled        = true,
  $package_ensure = 'present'
) {

  Swift_config<| |> ~> Service['swift-object-updater']
  Swift_config<| |> ~> Service['swift-object-auditor']

  swift::storage::generic { 'object':
    manage_service => $manage_service,
    enabled        => $enabled,
    package_ensure => $package_ensure,
  }

  include ::swift::params

  if $manage_service {
    if $enabled {
      $service_ensure = 'running'
    } else {
      $service_ensure = 'stopped'
    }
  }

  service { 'swift-object-updater':
    ensure   => $service_ensure,
    name     => $::swift::params::object_updater_service_name,
    enable   => $enabled,
    provider => $::swift::params::service_provider,
    require  => Package['swift-object'],
  }

  service { 'swift-object-auditor':
    ensure   => $service_ensure,
    name     => $::swift::params::object_auditor_service_name,
    enable   => $enabled,
    provider => $::swift::params::service_provider,
    require  => Package['swift-object'],
  }
}
