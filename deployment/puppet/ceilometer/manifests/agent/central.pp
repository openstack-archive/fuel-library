# Installs/configures the ceilometer central agent
#
# == Parameters
#  [*enabled*]
#    (optional) Should the service be enabled.
#    Defaults to true.
#
#  [*manage_service*]
#    (optional)  Whether the service should be managed by Puppet.
#    Defaults to true.
#
#  [*package_ensure*]
#    (optional) ensure state for package.
#    Defaults to 'present'
#
#  [*coordination_url*]
#    (optional) The url to use for distributed group membership coordination.
#    Defaults to undef.
#

class ceilometer::agent::central (
  $manage_service   = true,
  $enabled          = true,
  $package_ensure   = 'present',
  $coordination_url = undef,
) {

  include ::ceilometer::params

  Ceilometer_config<||> ~> Service['ceilometer-agent-central']

  Package['ceilometer-agent-central'] -> Service['ceilometer-agent-central']
  package { 'ceilometer-agent-central':
    ensure => $package_ensure,
    name   => $::ceilometer::params::agent_central_package_name,
    tag    => 'openstack',
  }

  if $manage_service {
    if $enabled {
      $service_ensure = 'running'
    } else {
      $service_ensure = 'stopped'
    }
  }

  Package['ceilometer-common'] -> Service['ceilometer-agent-central']
  service { 'ceilometer-agent-central':
    ensure     => $service_ensure,
    name       => $::ceilometer::params::agent_central_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
  }

  if $coordination_url {
    ensure_resource('ceilometer_config', 'coordination/backend_url',
      {'value' => $coordination_url})
  }
}
